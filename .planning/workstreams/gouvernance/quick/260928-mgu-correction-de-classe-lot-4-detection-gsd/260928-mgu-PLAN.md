---
phase: quick
plan: 260928-mgu
quick_id: 260928-mgu
type: execute
mode: quick-full
wave: 1
depends_on: []
files_modified:
  - plugin/planning-core/scripts/recalc-planning.sh
  - plugin/planning-core/scripts/tests/test-recalc-planning.sh
  - plugin/planning-core/references/modele-cycles.md
  - plugin/planning-core/CHANGELOG.md
autonomous: true
requirements: [MOTR-02, MOTR-04, MOTR-11, MOTR-12, MOTR-16, MOTR-18]

estimate:
  tokens: 40000
  raw_tokens: 40000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "detection_gsd() ne réimplémente PLUS aucune priorité du détecteur en Python : les prédicats _porte_marqueur_gsd, _porte_marqueur_partition, _porte_planning_version, _a_signal_de_code, la liste _SIGNAUX_DE_CODE et l'énumérateur _lister_compartiments sont supprimés ; le moteur appelle le VRAI detect-gsd-engine.sh en sous-processus (source unique de vérité, P44-D-01b, P44-D-01d)."
    - "Le sous-processus du détecteur tourne sous un environnement MAÎTRISÉ : copie de os.environ avec une seule surcharge, GSD_HOME = dossier du détecteur (qui existe toujours) — la priorité 1 du détecteur ne peut plus court-circuiter ses priorités 2/2bis/3, et le verdict d'écriture est indépendant de GSD_HOME/CLAUDE_CONFIG_DIR/HOME hérités (P44-D-01c, P44-D-02a)."
    - "Écriture autorisée SEULEMENT si le détecteur rend 3 ; tout autre cas (code 0, 2, un 1 improbable, code hors {0,2,3}, détecteur absent / en lien / non régulier / illisible, bash introuvable, échec de lancement) est fail-closed en non-concluante ou gsd — refus nommé, zéro fichier écrit (P44-D-02a)."
    - "_jeton_journal encode chaque champ de cloture.log en pourcent INJECTIF (tout caractère isspace(), '=' et '%' deviennent %XX par octet UTF-8) : deux valeurs distinctes donnent toujours deux jetons distincts — '3 4' et '3_4' ne s'écrasent plus, aucune clôture réellement nouvelle n'est absorbée par le dédoublonnage (P44-D-11, P44-D-09)."
    - "test-recalc-planning.sh passe à au moins 233 OK / 0 KO (180 OK sur ca185e4), sans aucune ligne en échec ni mutant survivant ; les 7 mutants dont la cible n'existe plus sont retirés, et R-ORACLE-DIFFERENTIEL / R-MATRICE-ENV couvrent leurs scénarios contre la source unique de vérité (P44-D-17)."
    - "Aucune régression hors périmètre : detect-gsd-engine.sh, les fixtures et les 8 suites sœurs de plugin/planning-core/scripts/tests/ sont inchangés et verts ; la sonde PY39 reste verte sous /bin/bash et /bin/zsh (P44-D-12)."
    - "modele-cycles.md et le CHANGELOG (paragraphe Lot 4 ajouté à l'entrée v2.8.0 existante, AUCUN bump de version) décrivent le comportement réel ; le contrôle croisé référence ↔ moteur reste à 42/42 (P44-D-18)."
  artifacts:
    - path: "plugin/planning-core/scripts/recalc-planning.sh"
      provides: "detection_gsd() par sous-processus sous env_maitrise (GSD_HOME = dossier du détecteur), motifs motif-bash-introuvable / motif-code-1-ferme ; _jeton_journal à encodage pourcent injectif"
      contains: "env=env_maitrise"
    - path: "plugin/planning-core/scripts/tests/test-recalc-planning.sh"
      provides: "R-DETECTEUR-LIEN, R-DETECTEUR-ILLISIBLE, R-DETECTEUR-CODE1-INATTENDU, R-ORACLE-DIFFERENTIEL, R-MATRICE-ENV, R-LABS-ADVERSES, R-INJECTIF-GENERATIF, R-INJECTIF-ROUNDTRIP ; MUT-ENV-NON-MAITRISE, MUT-CODE1-NON-GSD, MUT-BASH-INTROUVABLE ; MUT-SOUS-PROCESSUS et MUT-JOURNAL-SANITIZE recâblés"
      contains: "R-ORACLE-DIFFERENTIEL"
    - path: "plugin/planning-core/references/modele-cycles.md"
      provides: "table des codes du détecteur (ligne unique pour le code 1, fail-closed), paragraphe « Source UNIQUE de vérité », section « Assainissement structurel INJECTIF »"
      contains: "Source UNIQUE de vérité"
    - path: "plugin/planning-core/CHANGELOG.md"
      provides: "paragraphe « Lot 4 (correction de CLASSE) » sous l'entrée v2.8.0, citation d'arbitrage étendue au lot 4"
      contains: "Lot 4 (correction de CLASSE)"
  key_links:
    - from: "plugin/planning-core/scripts/recalc-planning.sh (detection_gsd)"
      to: "plugin/planning-core/scripts/detect-gsd-engine.sh"
      via: "subprocess.run([bash_bin, detect_sh, '--quiet', '--path', planning_abs], env=env_maitrise) — code de sortie seul, aucun sourcing"
      pattern: "env=env_maitrise"
    - from: "plugin/planning-core/scripts/recalc-planning.sh (_formater_ligne_journal, lignes_a_journaliser)"
      to: "plugin/planning-core/scripts/recalc-planning.sh (_jeton_journal)"
      via: "les 4 champs écrits ET la comparaison de dédoublonnage passent par le même encodage injectif"
      pattern: "_jeton_journal("
    - from: "plugin/planning-core/scripts/tests/test-recalc-planning.sh (R-ORACLE-DIFFERENTIEL)"
      to: "plugin/planning-core/scripts/detect-gsd-engine.sh"
      via: "oracle différentiel : verdict du moteur comparé au vrai détecteur lancé directement avec un GSD_HOME valide, sur 5 scénarios"
      pattern: "R-ORACLE-DIFFERENTIEL"
    - from: "plugin/planning-core/references/modele-cycles.md"
      to: "plugin/planning-core/scripts/recalc-planning.sh"
      via: "contrôle croisé de 42 jetons (sonde CONTRAT-CROISE de 44-04)"
      pattern: "CONTRAT-CROISE-OK 42 / 42"
---

# Plan — correction de classe lot 4, Phase 44 (détection GSD par le vrai détecteur, journal injectif)

<objective>
Documenter, re-vérifier et committer atomiquement le lot 4 de la correction ciblée de la Phase 44,
DÉJÀ ÉCRIT sur disque (arbre de travail, non indexé) : `detection_gsd()` appelle désormais le vrai
`detect-gsd-engine.sh` dans un environnement maîtrisé au lieu de reproduire ses priorités en Python
(P44-D-01b, P44-D-01c, P44-D-01d, P44-D-02a), et `_jeton_journal` passe à un encodage pourcent
injectif (P44-D-09, P44-D-11).

Purpose : le lot 3 avait fermé le repli du code 1 par une copie Python des priorités 2/2bis/3 du
détecteur. Revue et audit ont mesuré trois divergences de cette copie (un `package.json` en lien
symbolique, un `*.xcodeproj` en lien symbolique, un `STATE.md` aux octets UTF-8 invalides après le
frontmatter) : avec `GSD_HOME` inexistant, le moteur écrivait sur un planning que le vrai détecteur
classe en code 2. Le lot 4 corrige la CLASSE entière et non chaque cas. Il rend aussi le journal
injectif : l'ancien assainissement par `_` confondait `"3 4"` et `"3_4"`, ce qui pouvait faire
manquer une clôture réellement nouvelle au dédoublonnage.

Output : trois commits atomiques, dans l'ordre établi par les lots 1-3 (`fix(44)` → `test(44)` →
`docs(44)`, cf. `dab3f62`/`89270fa`/`22381c1`). Tous les contrôles ont été rejoués et sont verts
avant le commit.
</objective>

## Note de méthode (même régime que `260928-ccz-PLAN.md`)

Ce plan est rédigé APRÈS coup. L'implémentation, les tests de régression et les mutants sont déjà
sur disque et ont été vérifiés à la main. Le planificateur a rejoué lui-même, au moment de la
planification (2026-09-28), chaque contrôle listé ci-dessous, avec ces résultats :
`bash -n` OK sur les deux scripts,
`PY39-SYNTAXE-OK`, `CONTRAT-CROISE-OK 42 / 42`, `== Résultat : 233 OK · 0 KO ==` sans aucune
ligne en échec, les 8 suites sœurs vertes, `check-gate-touche.sh` en `RIEN-A-JUGER` (rc=0).
Observation vivante de la portée (règle MUTABLE-SCOPE) : `git diff --name-only c11a2b5` liste exactement les
4 fichiers de `files_modified`, et rien d'autre de suivi ; `detect-gsd-engine.sh`,
`workstream-policy.sh` et `plugin/planning-core/scripts/tests/fixtures/` n'ont aucun diff.
Les contrôles d'invariance ci-dessous comparent à `c11a2b5`, le HEAD de
`gouvernance/phase-44-moteur` au moment de la planification, et pas à l'index. Ils restent donc
probants avant comme après les commits de ce plan. Un diff sans révision explicite passerait à vide
une fois le changement committé.

Tracer-first : sans objet. Le plan ne construit aucune tranche nouvelle : il documente et commit un
travail déjà écrit. Le chemin de bout en bout (moteur → sous-processus → vrai détecteur → verdict →
écriture ou refus) est déjà prouvé par R-ORACLE-DIFFERENTIEL et R-MATRICE-ENV (Tâche 2).

**Discipline de commit (toutes les tâches)** :
- indexer UNIQUEMENT les chemins explicites de la tâche (`git add <chemin>`), jamais `git add -A`
  ni `git add .`. Le fichier non suivi `.planning/missions/2026-09-27-gouvernance-44.dag.json` est
  HORS périmètre : ne pas l'indexer, ne pas le modifier.
- messages en français, cohérents avec `dab3f62`/`89270fa`/`22381c1`.
- citation d'arbitrage reprise telle qu'elle est inscrite dans le CHANGELOG sur disque : « décision
  du head sous délégation technique de Willy, session principale, 2026-09-28 ».
- terminer chaque message par les deux lignes d'attribution de la session
  (`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` puis
  `Claude-Session: https://claude.ai/code/session_016gsZHV1FJA6mwVH1aV4RVt`).
- pas de trailer `Gate-Touche` : aucune surface surveillée par G-2 n'est touchée (mesuré).
- ne pas toucher `STATE.md` : c'est l'orchestrateur qui le tient, à la main, après le plan.
  N'appeler aucune commande `state.*`.

<execution_context>
@/Users/makwilmak/.claude/gsd-core/workflows/execute-plan.md
@/Users/makwilmak/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/workstreams/gouvernance/STATE.md
@CLAUDE.md
@.planning/workstreams/gouvernance/quick/260928-ccz-correction-cibl-e-lot-3-phase-44-d-doubl/260928-ccz-PLAN.md
@plugin/planning-core/scripts/recalc-planning.sh
@plugin/planning-core/scripts/detect-gsd-engine.sh
</context>

<tasks>

<task type="auto">
  <name>Tâche 1 : detection_gsd() par le vrai détecteur sous environnement maîtrisé, et encodage injectif du journal (recalc-planning.sh), puis commit fix(44)</name>
  <files>plugin/planning-core/scripts/recalc-planning.sh</files>
  <action>
Travail DÉJÀ FAIT sur disque. À vérifier, puis à committer seul.

1. Détection GSD, source unique de vérité (P44-D-01b, P44-D-01d, P44-D-02a) :
   - Suppression, dans le bloc « Détection GSD », de toute la réimplémentation Python du lot 3 : les
     quatre prédicats qui relisaient le frontmatter des STATE.md (marqueur GSD, marqueur de
     partition, `planning_version`), la liste figée des fichiers-signaux de code, le prédicat de
     signal de code (fichiers et dossiers `.xcodeproj`), et l'énumérateur des compartiments
     `workstreams/`.
   - Le commentaire d'en-tête du bloc est réécrit : il décrit la correction de CLASSE et nomme
     P44-D-01b/P44-D-01d.
   - `detection_gsd()` garde le contrôle de régularité du détecteur par `lstat`
     (motif-detecteur-irregulier).
   - `bash` est résolu par `shutil.which` SANS repli sur le nom nu. S'il est introuvable :
     `non-concluante`, avec un message sur stderr (motif-bash-introuvable).
   - Le sous-processus reçoit `env=env_maitrise`. C'est une copie de `os.environ`, jamais l'objet
     nu, avec UNE seule surcharge : `GSD_HOME` pointé sur `os.path.dirname(detect_sh)`, un dossier
     qui existe toujours. La priorité 1 du détecteur (chaîne GSD absente) ne peut donc plus
     court-circuiter ses priorités 2/2bis/3 (P44-D-01c).
   - Le code 0 donne `gsd` et le code 2 donne `non-concluante` (inchangés).
   - Code 1 : une seule ligne `return "non-concluante"  # motif-code-1-ferme`, fail-closed. Il n'y a
     plus aucun repli qui rejoue les marqueurs.
   - Tout autre code donne `non-concluante` (motif-repli-generique). L'écriture n'est donc
     autorisée que sur le code 3 (`non-gsd`).
2. Journal, encodage injectif (P44-D-09, P44-D-11) :
   - Suppression de l'expression régulière de réduction des espaces à `_`.
   - `_jeton_journal` parcourt la valeur caractère par caractère. Tout caractère pour lequel
     `isspace()` est vrai (U+2028, U+0085 et tous les espaces Unicode compris), tout `=` et le `%`
     d'échappement lui-même deviennent `%XX` : deux chiffres hexadécimaux majuscules par octet UTF-8.
   - Repli inchangé (`jeton or repli`).
   - Les appelants sont inchangés : `_formater_ligne_journal` (4 champs) et la comparaison de
     `lignes_a_journaliser` passent par la même fonction, donc le dédoublonnage compare toujours des
     jetons de même encodage.
3. Aucun autre fichier : `detect-gsd-engine.sh` reste inchangé (P44-D-01b), aucun sourcing.
4. Commit (après la vérification verte), en indexant ce seul fichier :
   `git add plugin/planning-core/scripts/recalc-planning.sh`. Message :
   `fix(44): detection_gsd() appelle le vrai détecteur sous environnement maîtrisé et encode le journal de façon injective (recalc-planning.sh)`,
   suivi d'un corps en puces qui reprend les points 1-2, la citation d'arbitrage et les deux lignes
   d'attribution.
  </action>
  <verify>
    <automated>bash -n plugin/planning-core/scripts/recalc-planning.sh && echo BASH-N-OK</automated>
    <automated>python3 - <<'PY39_SONDE_EOF'
import ast, sys
t = open("plugin/planning-core/scripts/recalc-planning.sh", encoding="utf-8").read()
lines = t.split("\n")
start = next((i for i, l in enumerate(lines) if "PY_RECALC_PLANNING_EOF" in l and "<<" in l), None)
if start is None:
    print("PY39-SYNTAXE-KO heredoc introuvable"); sys.exit(1)
end = next((i for i in range(start + 1, len(lines)) if lines[i].strip() == "PY_RECALC_PLANNING_EOF"), None)
if end is None:
    print("PY39-SYNTAXE-KO fermeture du heredoc introuvable"); sys.exit(1)
src = "\n".join(lines[start + 1:end])
try:
    ast.parse(src, feature_version=(3, 9))
except SyntaxError as e:
    print("PY39-SYNTAXE-KO", e); sys.exit(1)
import re
nested_fstring = (
    re.search(r"f\"[^\"\n]*\{[^{}\n]*\"[^{}\n]*\"[^{}\n]*\}", src)
    or re.search(r"f'[^'\n]*\{[^{}\n]*'[^{}\n]*'[^{}\n]*\}", src)
)
if nested_fstring:
    print("PY39-SYNTAXE-KO f-string PEP 701 (guillemets imbriqués identiques à ceux du délimiteur) détectée"); sys.exit(1)
print("PY39-SYNTAXE-OK")
PY39_SONDE_EOF
</automated>
    <automated>grep -c -F 'env=env_maitrise' plugin/planning-core/scripts/recalc-planning.sh</automated>
    <automated>grep -c -F 'env_maitrise["GSD_HOME"] = os.path.dirname(detect_sh)' plugin/planning-core/scripts/recalc-planning.sh</automated>
    <automated>grep -c -F 'return "non-concluante"  # motif-code-1-ferme' plugin/planning-core/scripts/recalc-planning.sh</automated>
    <automated>grep -c -F 'return "non-concluante"  # motif-bash-introuvable' plugin/planning-core/scripts/recalc-planning.sh</automated>
    <automated>grep -c -F '"%{:02X}".format(octet)' plugin/planning-core/scripts/recalc-planning.sh</automated>
    <automated>grep -v -E '^[[:space:]]*#' plugin/planning-core/scripts/recalc-planning.sh | grep -c -E '_porte_marqueur_gsd|_porte_marqueur_partition|_porte_planning_version|_a_signal_de_code|_SIGNAUX_DE_CODE|_lister_compartiments|_JOURNAL_ESPACE_RE'</automated>
    <automated>grep -v -E '^[[:space:]]*#' plugin/planning-core/scripts/recalc-planning.sh | grep -c -E '^[[:space:]]*(source|\.)[[:space:]].*detect-gsd-engine'</automated>
    <automated>git diff --quiet c11a2b5 -- plugin/planning-core/scripts/detect-gsd-engine.sh plugin/planning-core/scripts/workstream-policy.sh && echo DETECTEUR-INCHANGE</automated>
    <fails_when>
- `bash -n` échoue.
- La sonde n'imprime pas `PY39-SYNTAXE-OK` comme dernière ligne.
- L'un des cinq `grep -c -F` positifs n'imprime pas exactement `1`.
- L'un des deux `grep -c` négatifs (hors lignes de commentaire) imprime autre chose que `0` : il
  reste un vestige de la réimplémentation, ou un sourcing du détecteur.
- `DETECTEUR-INCHANGE` n'est pas imprimé.

Portabilité bash/zsh de la sonde PY39 (déjà mesurée verte sous les deux) : écrire le corps de la
sonde, heredoc compris, dans un fichier du scratchpad de la session exécutrice, jamais dans le dépôt.
Le lancer ensuite depuis la racine du worktree, avec `/bin/bash <fichier>` puis `/bin/zsh <fichier>` :
chacun doit imprimer `PY39-SYNTAXE-OK`. Si le bac à sable refuse de lancer un fichier de script,
rejouer le heredoc ci-dessus tel quel dans chacun des deux shells.
    </fails_when>
  </verify>
  <done>
- Un commit `fix(44): …` sur `gouvernance/phase-44-moteur` ne porte QUE
  `plugin/planning-core/scripts/recalc-planning.sh`.
- `bash -n` et `PY39-SYNTAXE-OK` sont verts.
- detection_gsd() lance le vrai détecteur avec `env=env_maitrise` (GSD_HOME = dossier du détecteur).
- Le code 1 est fermé (`motif-code-1-ferme`) et bash introuvable est fermé (`motif-bash-introuvable`).
- Aucun vestige de la réimplémentation Python (0 occurrence hors commentaires).
- `_jeton_journal` encode en `%XX` par octet UTF-8.
- detect-gsd-engine.sh est inchangé.
  </done>
</task>

<task type="auto">
  <name>Tâche 2 : suite test-recalc-planning.sh — retrait des 7 mutants orphelins, oracle différentiel, matrice d'environnement, labs adverses, preuve d'injectivité ; puis commit test(44)</name>
  <files>plugin/planning-core/scripts/tests/test-recalc-planning.sh</files>
  <action>
Travail DÉJÀ FAIT sur disque. À vérifier, puis à committer seul (seul fichier de
`plugin/planning-core/scripts/tests/` touché, fixtures comprises inchangées).

1. En-tête de la suite (l. 50-71) : réécrit pour lister les cas du lot 4 et nommer les 7 mutants
   retirés. Ces sept mutants sont MUT-CHAINE-ABSENTE, MUT-PARTITION-ABSENTE, MUT-MARQUEUR-RACINE,
   MUT-MARQUEUR-COMPARTIMENT, MUT-PARTITION-COMPARTIMENT, MUT-CODE1-SANS-MARQUEUR et
   MUT-CODE1-SOCLE-SIGNAL. Leur ligne cible, la réimplémentation Python, n'existe plus : ils sont
   retirés, sans être remplacés un par un.
2. Nouveaux cas de régression (P44-D-17), tous verts au planning :
   - R-DETECTEUR-LIEN, R-DETECTEUR-ILLISIBLE (détecteur en `chmod 000`) et
     R-DETECTEUR-CODE1-INATTENDU (détecteur factice qui sort en 1) : refus en code 3 et empreinte
     du lab inchangée.
   - R-ORACLE-DIFFERENTIEL : 5 scénarios (terrain libre, marqueur racine, marqueur de compartiment,
     partition, socle+signal). Le verdict du moteur est comparé à celui du vrai détecteur lancé
     directement avec un GSD_HOME valide.
   - R-MATRICE-ENV : les 5 mêmes scénarios × 6 colonnes d'environnement hérité (normal, GSD_HOME
     inexistant/vide/piégé, CLAUDE_CONFIG_DIR vide, HOME vide). Code de sortie identique partout,
     et STATE.md écrit identique à la colonne de référence sur le terrain libre (35 assertions).
   - R-LABS-ADVERSES : les trois divergences mesurées au lot 3, chacune combinée au socle
     planning-core. Refus en code 3, marqueur `planning_version` intact octet pour octet.
   - R-INJECTIF-GENERATIF : 2000 paires, graine fixe, zéro collision, round-trip pourcent et
     lisibilité par `LIGNE_JOURNAL_RE`.
   - R-INJECTIF-ROUNDTRIP : deux exécutions réelles successives, « 3 4 » puis « 3_4 ». Elles
     produisent deux lignes distinctes, et `cloture_ajouts=1` au second recalcul.
3. Nouveaux mutants, chacun avec sa trace assertion / attendu (original) / obtenu (mutant) :
   - MUT-ENV-NON-MAITRISE neutralise la surcharge de GSD_HOME. Il est tué par R13 (b) sous un
     GSD_HOME hérité cassé : l'original rend 0, le mutant rend 3.
   - MUT-CODE1-NON-GSD rouvre l'écriture sur le code 1 : l'original rend 3, le mutant rend 0.
   - MUT-BASH-INTROUVABLE rouvre l'écriture quand bash est introuvable : l'original rend 3, le
     mutant rend 0.
4. Mutants recâblés sur le nouveau code :
   - MUT-SOUS-PROCESSUS vise désormais `motif-sous-processus-en-echec`.
   - MUT-JOURNAL-SANITIZE neutralise la condition d'encodage pourcent de `_jeton_journal`.
5. Commit (après la vérification verte), en indexant ce seul fichier :
   `git add plugin/planning-core/scripts/tests/test-recalc-planning.sh`. Message :
   `test(44): couvre la détection GSD par le vrai détecteur et l'encodage injectif du journal (lot 4)`,
   corps en puces (cas ajoutés, mutants ajoutés/recâblés/retirés et pourquoi, 180 → 233 OK /
   0 KO), citation d'arbitrage, puis les deux lignes d'attribution.
  </action>
  <verify>
    <automated>bash -n plugin/planning-core/scripts/tests/test-recalc-planning.sh && echo BASH-N-OK</automated>
    <automated>bash plugin/planning-core/scripts/tests/test-recalc-planning.sh > "$SCRATCH/recalc-lot4.out" 2>&1; echo "rc=$?"</automated>
    <automated>tail -1 "$SCRATCH/recalc-lot4.out"</automated>
    <automated>grep -c -E '✗|NON TUÉ' "$SCRATCH/recalc-lot4.out"</automated>
    <automated>grep -c -E 'MUT-(ENV-NON-MAITRISE|CODE1-NON-GSD|BASH-INTROUVABLE|SOUS-PROCESSUS|JOURNAL-SANITIZE) TUÉ' "$SCRATCH/recalc-lot4.out"</automated>
    <automated>grep -c -E '✓ (R-DETECTEUR-LIEN|R-DETECTEUR-ILLISIBLE|R-DETECTEUR-CODE1-INATTENDU|R-ORACLE-DIFFERENTIEL|R-MATRICE-ENV|R-LABS-ADVERSES|R-INJECTIF-GENERATIF|R-INJECTIF-ROUNDTRIP) ' "$SCRATCH/recalc-lot4.out"</automated>
    <automated>grep -v -E '^[[:space:]]*#' plugin/planning-core/scripts/tests/test-recalc-planning.sh | grep -c -E 'make_recalc_mutant (CHAINE-ABSENTE|PARTITION-ABSENTE|MARQUEUR-RACINE|MARQUEUR-COMPARTIMENT|PARTITION-COMPARTIMENT|CODE1-SANS-MARQUEUR|CODE1-SOCLE-SIGNAL)'</automated>
    <automated>bash plugin/planning-core/scripts/tests/test-check-planning-state.sh 2>&1 | tail -1</automated>
    <automated>bash plugin/planning-core/scripts/tests/test-detect-gsd-engine.sh 2>&1 | tail -1</automated>
    <automated>bash plugin/planning-core/scripts/tests/test-detect-planning-debt.sh 2>&1 | tail -1</automated>
    <automated>bash plugin/planning-core/scripts/tests/test-planning-context-hardening.sh 2>&1 | tail -1</automated>
    <automated>bash plugin/planning-core/scripts/tests/test-planning-core.sh 2>&1 | tail -1</automated>
    <automated>bash plugin/planning-core/scripts/tests/test-planning-hooks.sh 2>&1 | tail -1</automated>
    <automated>bash plugin/planning-core/scripts/tests/test-workstream-policy.sh 2>&1 | tail -1</automated>
    <automated>bash plugin/planning-core/scripts/tests/test-workstream-symlink-escape.sh 2>&1 | tail -1</automated>
    <automated>git diff --stat c11a2b5 -- plugin/planning-core/scripts/tests/</automated>
    <automated>git diff --quiet c11a2b5 -- plugin/planning-core/scripts/tests/fixtures && echo FIXTURES-INCHANGEES</automated>
    <fails_when>
`SCRATCH` désigne le scratchpad de la session exécutrice, jamais un chemin du dépôt. La suite
dure plusieurs minutes : prévoir un délai d'expiration suffisant (≥ 10 min).

La tâche échoue dans l'un des cas suivants :
- `rc` n'est pas `0`.
- La dernière ligne de la sortie n'est pas de la forme `== Résultat : N OK · 0 KO ==` avec
  N ≥ 233 (233 mesuré au planning).
- Le comptage des lignes en échec ou des mutants survivants n'imprime pas `0`.
- Le comptage des 5 mutants du lot 4 tués n'imprime pas `5`.
- Le comptage des lignes vertes des 8 cas R-* du lot 4 imprime moins de `57` (valeur mesurée au
  planning).
- Le comptage des invocations des 7 mutants retirés (hors commentaires) n'imprime pas `0`.
- L'une des 8 suites sœurs ne se termine pas par sa ligne verte mesurée :
  - `== résultat : 19 ok, 0 ko ==` (check-planning-state)
  - `== résultat : 26 ok, 0 ko ==` (detect-gsd-engine)
  - `== résultat : 10 passés, 0 échoués ==` (detect-planning-debt)
  - `== résultat : 38 passés, 0 échoués ==` (planning-context-hardening)
  - `== résultat : 14 passés, 0 échoués ==` (planning-core)
  - `== BILAN : 42 PASS / 0 FAIL ==` (planning-hooks)
  - `== resultat : 22 ok, 0 ko, 0 skip ==` (workstream-policy)
  - `== resultat : 10 ok, 0 ko ==` (workstream-symlink-escape)

  Un nombre de cas différent est admis tant que le compteur d'échecs reste à 0.
- `git diff --stat c11a2b5 -- plugin/planning-core/scripts/tests/` liste autre chose que
  `test-recalc-planning.sh`.
- `FIXTURES-INCHANGEES` n'est pas imprimé.
    </fails_when>
  </verify>
  <done>
- Un commit `test(44): …` ne porte QUE `plugin/planning-core/scripts/tests/test-recalc-planning.sh`.
- La suite rend `== Résultat : 233 OK · 0 KO ==` (au moins 233), sans ligne en échec ni mutant
  survivant.
- Les 5 mutants du lot 4 sont tués, et les 7 mutants orphelins ne sont plus invoqués.
- Les 8 suites sœurs sont vertes et non modifiées, et les fixtures sont inchangées.
  </done>
</task>

<task type="auto">
  <name>Tâche 3 : documentation du lot 4 (modele-cycles.md, CHANGELOG v2.8.0 sans bump) et contrôle croisé 42/42 ; puis commit docs(44)</name>
  <files>plugin/planning-core/references/modele-cycles.md, plugin/planning-core/CHANGELOG.md</files>
  <action>
Travail DÉJÀ FAIT sur disque. À vérifier, puis à committer (ces deux fichiers seulement).

1. `modele-cycles.md`, table des codes du détecteur :
   - Les trois lignes du code 1 (marqueur trouvé / socle+signal reproduit en Python / aucun
     signal) sont remplacées par UNE ligne : code 1 improbable, verdict `non-concluante`,
     écriture refusée.
   - Les lignes 0, 2, 3 et « tout autre code » sont inchangées.
2. `modele-cycles.md`, paragraphe sous la table : réécrit sous le titre « Source UNIQUE de vérité —
   le VRAI détecteur, jamais une copie (correction de CLASSE, lot 4) ». Il fait l'historique des
   lots 2 et 3, puis énumère les trois divergences mesurées sur ca185e4. Il décrit ensuite :
   - l'appel au vrai détecteur sous GSD_HOME = dossier du détecteur ;
   - le code 1 en fail-closed ;
   - la propriété d'indépendance vis-à-vis de GSD_HOME/CLAUDE_CONFIG_DIR/HOME/PATH hérités et du
     cwd (P44-D-01b, P44-D-01d) ;
   - la liste des refus fail-closed nommés.

   Le renvoi à la Phase 45 est conservé.
3. `modele-cycles.md`, section journal : devient « Assainissement structurel INJECTIF de chaque
   champ ». Elle décrit :
   - l'encodage `%XX` par octet UTF-8 des caractères `isspace()`, de `=` et de `%` ;
   - la non-injectivité de l'ancien schéma, qui violait P44-D-11 ;
   - la preuve par R-INJECTIF-GENERATIF/R-INJECTIF-ROUNDTRIP.

   La mention « aucun contrôle de sens » (P44-D-09) est conservée.
4. `CHANGELOG.md` :
   - Un paragraphe « Lot 4 (correction de CLASSE) » est ajouté à la fin des puces de l'entrée
     `[v2.8.0]` EXISTANTE. C'est un complément, PAS une nouvelle version (P44-D-18, ADR-073).
     `plugin/planning-core/VERSION` reste `v2.8.0`. Aucune `VERSION` racine, aucun manifeste,
     aucun tag n'est touché.
   - La phrase d'attribution des décisions est étendue au lot 4 (« source unique de vérité pour
     la détection GSD, encodage injectif du journal »), avec la même citation d'arbitrage datée.
5. Commit (après la vérification verte), en indexant ces deux fichiers seulement :
   `git add plugin/planning-core/references/modele-cycles.md plugin/planning-core/CHANGELOG.md`.
   Message :
   `docs(44): documente le lot 4 (source unique de vérité pour la détection GSD, journal injectif) au CHANGELOG et à modele-cycles.md`,
   citation d'arbitrage, puis les deux lignes d'attribution.
6. Après ce troisième commit, rejouer `check-gate-touche.sh` sur la branche. Il doit rendre
   RIEN-A-JUGER, rc=0.
  </action>
  <verify>
    <automated>python3 -c 'import sys; r=open("plugin/planning-core/references/modele-cycles.md",encoding="utf-8").read(); m=open("plugin/planning-core/scripts/recalc-planning.sh",encoding="utf-8").read(); jetons=["cycles-v1","CLOTURE.md","DEROGATION.md",".recalc-cache.json","cache_schema_version","date=observation","_bancs","recherches","intel","sketches","_archive","registres","derogation-sans-auteur","derogation-invalide","fichier-non-regulier","erreur-de-lecture","frontmatter-invalide","hors-cadrage","registre-invalide","avant-cadrage-clos","plan-direct-et-plans","fichier-de-plan-au-niveau-phase","SUMMARY.md-sans-PLAN.md","CLOTURE.md-sans-PLAN.md","VERDICT.md-sans-PLAN.md","ecrit-invalide","VERDICT.md-sans-CLOTURE.md","SUMMARY.md-sans-CLOTURE.md","livrable-absent","SUMMARY.md-sans-VERDICT.md","verdict-invalide","SUMMARY.md-avec-verdict-en-echec","verdict-passe-sans-SUMMARY.md","combinaison-non-prevue","plan-indetermine","phase-indeterminee","CYCLE.md-absent","plans-clos","plans-abandonnes","combinaison de signaux non prévue","verdict passé, SUMMARY absent","SUMMARY.md sans PLAN.md"]; e=[(j,"reference" if j not in r else "moteur") for j in jetons if j not in r or j not in m]; [print("ECART",j,"absent de la",o) for j,o in e]; print("CONTRAT-CROISE-OK" if not e else "CONTRAT-CROISE-KO", len(jetons)-len(e), "/", len(jetons))'</automated>
    <automated>grep -c -F 'Source UNIQUE de vérité' plugin/planning-core/references/modele-cycles.md</automated>
    <automated>grep -c -F 'Assainissement structurel INJECTIF' plugin/planning-core/references/modele-cycles.md</automated>
    <automated>grep -c '^| 1 | improbable' plugin/planning-core/references/modele-cycles.md</automated>
    <automated>grep -c '^| 1, ' plugin/planning-core/references/modele-cycles.md</automated>
    <automated>grep -c -F 'Lot 4 (correction de CLASSE)' plugin/planning-core/CHANGELOG.md</automated>
    <automated>grep -c '^## \[v2.8.0\]' plugin/planning-core/CHANGELOG.md</automated>
    <automated>git diff --quiet c11a2b5 -- VERSION plugin/planning-core/VERSION plugin/planning-core/module.json plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json && echo AUCUN-BUMP</automated>
    <automated>bash scripts/check-gate-touche.sh 2>&1 | tail -1</automated>
    <fails_when>
La tâche échoue dans l'un des cas suivants :
- La sonde du contrôle croisé (reprise telle quelle de 44-04) n'imprime pas
  `CONTRAT-CROISE-OK 42 / 42`, ou imprime une ligne `ECART`.
- L'un des comptages positifs (« Source UNIQUE de vérité », « Assainissement structurel
  INJECTIF », ligne unique du code 1, « Lot 4 (correction de CLASSE) », titre `[v2.8.0]`)
  n'imprime pas exactement `1`.
- Le comptage des anciennes lignes du code 1 à trois variantes n'imprime pas `0`.
- `AUCUN-BUMP` n'est pas imprimé : une version a été touchée, ce qui est interdit (P44-D-18, pas
  de release gouvernance avant la clôture de fiabilite-v1.0).
- La dernière ligne de `check-gate-touche.sh`, rejoué après le troisième commit, ne commence pas
  par `RIEN-A-JUGER`.
    </fails_when>
  </verify>
  <done>
- Un commit `docs(44): …` ne porte QUE `modele-cycles.md` et `CHANGELOG.md`.
- Le contrôle croisé référence ↔ moteur est à 42/42.
- La table des codes et les deux sections décrivent le comportement réel du lot 4.
- Le CHANGELOG porte le paragraphe Lot 4 sous v2.8.0, sans aucun bump de version ni tag.
- `check-gate-touche.sh` rend RIEN-A-JUGER après les trois commits.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| environnement hérité → sous-processus du détecteur | GSD_HOME, CLAUDE_CONFIG_DIR, HOME et PATH viennent de l'appelant ; ils ne doivent plus pouvoir changer le verdict d'écriture |
| disque du lab → moteur | STATE.md, les fichiers-signaux et les liens symboliques sont lus sans confiance |
| valeurs lues (VERDICT.md, frontmatter) → cloture.log | valeurs arbitraires (P44-D-09) recopiées dans un journal append-only relu par regex |
| exécuteur → index git | un arbre de travail qui contient un fichier non suivi hors périmètre |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-Q260928mgu-01 | Tampering / Elevation | `detection_gsd()` — GSD_HOME hérité forcé vers un chemin inexistant pour obtenir le code 1 et contourner le refus « migration à examiner » | high | mitigate | `env=env_maitrise` avec GSD_HOME = dossier du détecteur ; code 1 fail-closed (`motif-code-1-ferme`) ; prouvé par R-MATRICE-ENV (6 colonnes), MUT-ENV-NON-MAITRISE et MUT-CODE1-NON-GSD tués |
| T-Q260928mgu-02 | Tampering | la copie Python des priorités du détecteur diverge de l'original (lien symbolique, UTF-8 invalide) | high | mitigate | copie supprimée, vrai détecteur appelé ; R-LABS-ADVERSES rejoue les 3 divergences, R-ORACLE-DIFFERENTIEL compare au détecteur direct |
| T-Q260928mgu-03 | Spoofing | détecteur remplacé par un lien symbolique, rendu illisible, ou `bash` absent du PATH | medium | mitigate | contrôle `lstat` régulier, `shutil.which` sans repli, refus nommés ; R-DETECTEUR-LIEN, R-DETECTEUR-ILLISIBLE, MUT-BASH-INTROUVABLE |
| T-Q260928mgu-04 | Tampering / Repudiation | `cloture.log` — valeur piégée qui forge un second enregistrement, ou collision de jetons qui masque une clôture nouvelle | medium | mitigate | encodage pourcent injectif de `_jeton_journal` ; R-INJECTIF-GENERATIF (2000 paires), R-INJECTIF-ROUNDTRIP, MUT-JOURNAL-SANITIZE |
| T-Q260928mgu-05 | Tampering | un commit qui embarque le fichier non suivi `.planning/missions/2026-09-27-gouvernance-44.dag.json`, ou mélange les sujets | low | mitigate | `git add` sur chemins explicites seulement, un commit par tâche |
| T-Q260928mgu-06 | Denial of Service | détecteur qui ne rend pas la main | low | accept | `timeout=30` inchangé ; l'exception tombe dans le refus générique, jamais dans une écriture |
</threat_model>

<verification>
Après les trois commits :
1. `git log --oneline -3` montre `docs(44)` → `test(44)` → `fix(44)` au-dessus de `c11a2b5`.
2. `git show --stat --format=%s HEAD~2 HEAD~1 HEAD` montre un fichier par commit pour fix et
   test, et deux fichiers pour docs.
3. `git status --short` ne liste plus aucun des 4 fichiers. Seul reste le fichier non suivi
   `.planning/missions/2026-09-27-gouvernance-44.dag.json`, hors périmètre, non indexé.
4. `bash scripts/check-gate-touche.sh 2>&1 | tail -1` commence par `RIEN-A-JUGER` (rc=0).
5. Ce qui n'a pas été rejoué : le passage en lecture seule sur les deux labs réels
   (`44-PASSAGE-LABS.md`). Il est hors de ce lot : aucune écriture sur un lab réel n'a lieu ici.
</verification>

<success_criteria>
- Trois commits atomiques, dans l'ordre fix → test → docs. Chacun ne porte que ses fichiers, avec
  un message en français, la citation d'arbitrage datée et les lignes d'attribution.
- Contrôles verts :
  - `bash -n` ×2 ;
  - `PY39-SYNTAXE-OK` sous bash et zsh ;
  - `CONTRAT-CROISE-OK 42 / 42` ;
  - `== Résultat : 233 OK · 0 KO ==` (au moins 233), sans ligne en échec ni mutant survivant ;
  - 8 suites sœurs vertes et non modifiées ;
  - `AUCUN-BUMP` ;
  - `RIEN-A-JUGER`.
- Aucun changement à `detect-gsd-engine.sh`, aux fixtures, à une `VERSION`, à `STATE.md` ou au
  DAG de mission.
</success_criteria>

<output>
Créer `.planning/workstreams/gouvernance/quick/260928-mgu-correction-de-classe-lot-4-detection-gsd/260928-mgu-SUMMARY.md` une fois le plan exécuté.
</output>
