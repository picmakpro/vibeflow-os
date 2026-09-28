# Requirements: VibeFlow Dev Orchestrator (VFDO) — gouvernance-labs-v1.0

**Defined:** 2026-09-23

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FABR-01 | Phase 42 | Complete |
| FABR-02 | Phase 42 | Complete |
| FABR-03 | Phase 42 | Complete — 42-05 (I1,I4,I5,I6,I7) + 42-06 (I2,I3 monde fermé) ; cochée à la main (`requirements.mark-complete` résout vers `fiabilite` sur ce dépôt) |
| FABR-04 | Phase 42 | Complete — 42-06 (découverte récursive D-10) ; cochée à la main |
| FABR-05 | Phase 42 | Complete — 42-02/42-03/42-05/42-06 (corpus conforme, T76 déjà correct depuis v2.63.2 D-13) ; cochée à la main |
| FABR-06 | Phase 43 | Complete — 43-VERIFICATION.md passed 10/10 (d7dc755) ; cochée à la main |
| FABR-07 | Phase 43 | Complete — 43-VERIFICATION.md passed 10/10 (d7dc755) ; cochée à la main |
| FABR-08 | Phase 43 | Complete — 43-VERIFICATION.md passed 10/10 (d7dc755) ; cochée à la main |
| FABR-09 | Phase 43 | Complete — 43-VERIFICATION.md passed 10/10 (d7dc755) ; cochée à la main |
| FABR-10 | Phase 43 | Complete — 43-VERIFICATION.md passed 10/10 (d7dc755) ; cochée à la main |
| MOTR-01 | Phase 44 | Complete — 44-VERIFICATION.md passed 18/18 (267b041) ; cochée à la main |
| MOTR-02 | Phase 44 | Complete — 44-VERIFICATION.md passed 18/18 (267b041) ; cochée à la main |
| MOTR-03 | Phase 44 | Complete — 44-VERIFICATION.md passed 18/18 (267b041) ; cochée à la main |
| MOTR-04 | Phase 44 | Complete — 44-VERIFICATION.md passed 18/18 (267b041) ; cochée à la main |
| MOTR-05 | Phase 44 | Complete — 44-VERIFICATION.md passed 18/18 (267b041) ; cochée à la main |
| MOTR-06 | Phase 44 | Complete — 44-VERIFICATION.md passed 18/18 (267b041) ; cochée à la main |
| MOTR-07 | Phase 44 | Complete — 44-VERIFICATION.md passed 18/18 (267b041) ; cochée à la main |
| MOTR-08 | Phase 44 | Complete — 44-VERIFICATION.md passed 18/18 (267b041) ; cochée à la main |
| MOTR-09 | Phase 44 | Complete — 44-VERIFICATION.md passed 18/18 (267b041) ; cochée à la main |
| MOTR-10 | Phase 44 | Complete — 44-VERIFICATION.md passed 18/18 (267b041) ; cochée à la main |
| MOTR-11 | Phase 44 | Complete — 44-VERIFICATION.md passed 18/18 (267b041) ; cochée à la main |
| MOTR-12 | Phase 44 | Complete — 44-VERIFICATION.md passed 18/18 (267b041) ; cochée à la main |
| MOTR-13 | Phase 44 | Complete — 44-VERIFICATION.md passed 18/18 (267b041) ; cochée à la main |
| MOTR-14 | Phase 44 | Complete — 44-VERIFICATION.md passed 18/18 (267b041) ; cochée à la main |
| MOTR-15 | Phase 44 | Complete — 44-VERIFICATION.md passed 18/18 (267b041) ; cochée à la main |
| MOTR-16 | Phase 44 | Complete — 44-VERIFICATION.md passed 18/18 (267b041) ; cochée à la main |
| MOTR-17 | Phase 44 | Complete — 44-VERIFICATION.md passed 18/18 (267b041) ; cochée à la main |
| MOTR-18 | Phase 44 | Complete — 44-VERIFICATION.md passed 18/18 (267b041) ; cochée à la main |

## Milestone gouvernance-labs-v1.0 — « le planning métier tenu par une machine » (inscrit 2026-09-23)

> Polarité gouvernance (Willy). Sources : `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md`,
> `2026-09-22-moteur-planning-metier-design.md`, `2026-09-23-initialisation-lab-design.md`. Préfixe `FABR`
> vérifié libre par `grep -rn 'FABR-' .planning/ plugin/ docs/` le 2026-09-23 (seule occurrence : le
> cadrage `42-CONTEXT.md` qui les propose). Les phases 43 à 50 recevront leurs familles à leur cadrage.

### Fabrique — manifeste daté et invariants du gate des agents (Phase 42)
- [x] **FABR-01**: Les listes de référence de `check-agents.sh` (outils, champs de frontmatter, types natifs, modèles, modes de permission, niveaux d'effort) vivent dans un manifeste daté versionné, source unique sans copie de repli dans le script ; chaque liste porte sa date de vérification et sa source ; un manifeste absent ou illisible est un refus explicite (`42-CONTEXT.md` D-01, D-03)
- [x] **FABR-02**: Un manifeste périmé (au-delà de la validité qu'il déclare) rend le gate INDÉTERMINÉ (exit 3) en CI du dépôt, un avertissement chez l'utilisateur (hook `SessionStart`, garde d'écriture), et ne peut jamais refuser sur une liste fermée (D-02, D-04, D-05)
- [x] **FABR-03**: Le gate refuse les violations des invariants I1 à I7 selon les définitions D-06 à D-09 (I2/I3 sous `--resolve-agents=strict` seulement) ; chaque invariant naît avec son jumeau négatif, dont la mutation est prouvée rouge
- [x] **FABR-04**: La découverte des agents est récursive, et ses exclusions (fichiers qui ne sont pas des agents) sont prouvées par un cas de test (D-10)
- [x] **FABR-05**: Le corpus d'agents du dépôt passe `--strict` et `--resolve-agents=strict` avec les invariants armés ; un commit par module touché avec son bump de patch ; le test qui verrouillait une affirmation périmée sur la profondeur de dispatch est corrigé (D-11, D-12, D-13)

### Fabrique — gate des skills par nature et alignement de skill-creator (Phase 43)
- [x] **FABR-06**: `check-skills.sh` (nouveau, miroir de `check-agents.sh`, contrat de sortie 0/1/3 identique, F13) refuse tout `SKILL.md` déclaré `vf-nature: procedure` (frontmatter `vf-nature: referentiel | outil | procedure`, défaut « outil ») qui n'a ni bloc `ecrit:` ni rubrique de juge ; un `SKILL.md` `procedure` avec les deux passe (`43-CONTEXT.md` D-Q1, D-Q2)
- [x] **FABR-07**: `check-skills.sh` détecte l'écart entre la déclaration factuelle en frontmatter (gate bloquant / livrable remis à un tiers / couche de qualité) et des motifs de forme procédurale trouvés indépendamment dans la prose du corps, et le signale en avertissement (exit 0, diagnostic imprimé) — jamais en refus (exit 1) — pour cette phase ; le corpus existant en dérive n'est pas corrigé ici (D-Q1, D-Q5)
- [x] **FABR-08**: `plugin/skill-creator/skills/skill-creator/SKILL.md` (moteur interne) ET `plugin/skill-creator/skills/skill-creator-workflow/SKILL.md` (workflow templaté) posent chacun la question `vf-nature`, avec le même défaut « outil », sans fusionner cette question avec l'étape existante « nature du sujet » (D-Q2, D-Q6)
- [x] **FABR-09**: `check-instruction-budget.sh` (socle repris, pas de réécriture) refuse tout `SKILL.md` sous `plugin/*/skills/**/SKILL.md` au-delà de 500 lignes, ET refuse toute hausse du socle du bootstrap : la mesure du jour du socle minimal d'un lab (fermeture `resolve-deps.sh conductor` + skill `installer` + commandes du plugin, ≈ 2 499 tokens estimés à la planification) devient la ligne de baseline `@bootstrap:socle` de `.planning/instruction-budget-baselines.tsv`, et toute mesure au-dessus de cette ligne est refusée (`DEPASSEMENT-BOOTSTRAP`, rc 1 sous ratchet armé — jamais un simple avertissement) ; le plafond ADR-029 de 2000 tokens du bootstrap reste un OBJECTIF signalé (jeton `AU-DESSUS-PLAFOND-ADR029`), non bloquant ; avec le même manifeste daté que la Phase 42 étendu des listes propres aux skills ; le commit qui ajoute la ligne `@bootstrap:socle` porte la citation de la décision et l'ajout est signalé à la revue code owner de Samuel (D-Q4 ; option ratchet-socle, décision déléguée par Willy au head (/vf-decide), AskUserQuestion session principale, 2026-09-26)
- [x] **FABR-10**: `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` §1.2/§7.2 est amendé (compte exact de 4 agents `vf-mcp-consumer: true`, `vf-reviewer` cité comme consommateur Xcode, reformulation « deux besoins distincts » conforme à ADR-051 décision 1) ; `inject-mcp-tools.sh` refuse une valeur `vf-mcp-tools` malformée au lieu d'un no-op silencieux (durcissement a, T22) ; `inject-mcp-tools.sh` signale un serveur nommé absent de l'union des scopes projet+global au lieu d'un no-op silencieux (durcissement b, T16, jugé contre l'union ADR-051-B) ; les textes ne nommant que `vf-mcp-consumer` (`plugin/_internal/vibeflow-update.sh:1276,1308,2423`, `plugin/conductor/skills/vf-calibrate/SKILL.md:92`) mentionnent aussi `vf-mcp-tools` (durcissement c) (D-Q3)

### Moteur — modèle de données et recalcul d'état dérivé du disque (Phase 44)

> Préfixe `MOTR` vérifié libre par `git grep -E 'MOTR-[0-9]'` le 2026-09-27 (0 fichier). Chaque
> exigence dérive d'une décision de `44-CONTEXT.md` (préfixe `P44-D-NN` recommandé, ADR-075) et ne
> pose aucune décision nouvelle.

- [x] **MOTR-01**: Le modèle de données d'un lab (`cycles/`, `phases/`, `CYCLE.md`, `CADRAGE.md`
  avec sa colonne structurante, `PLAN.md` avec le champ `ecrit:`, le fichier marqueur de clôture,
  `VERDICT.md`, `SUMMARY.md`, la liste fermée des emplacements annexes) est écrit et outillé dans
  `plugin/planning-core/`, en remplacement de son socle métier existant, sans toucher à
  `~/.claude/gsd-core/`, `.claude/gsd-core/` ni `plugin/dev-orchestrator/`, ni dépendre de leur
  code (`44-CONTEXT.md` P44-D-01, P44-D-01a, P44-D-01d)
- [x] **MOTR-02**: L'altitude lab que `planning-core` sert aussi aux labs dev (index des projets,
  compartiments, `workstream-policy.sh`, `detect-planning-debt.sh`, hooks existants) reste
  inchangée à l'identique, prouvée par ses suites existantes
  (`plugin/planning-core/scripts/tests/*.sh`) vertes sans modification de ces suites ; un lab dev
  n'est jamais réécrit (P44-D-01b, P44-D-01c)
- [x] **MOTR-03**: Le recalcul n'écrit que si `.planning/config.json` déclare le nouveau schéma via
  la clé `planning_version` existante (valeur nouvelle) ; sans cette déclaration, il refuse sans
  rien toucher (aucun fichier créé, modifié ou supprimé, cache compris), code de sortie non nul,
  message nommant la déclaration attendue (P44-D-02)
- [x] **MOTR-04**: Un mode lecture seule calcule la dérivation sur n'importe quel planning,
  adhérent ou non, et l'écrit uniquement sur la sortie standard (aucun fichier écrit, pas même le
  cache) ; un planning GSD détecté est refusé en mode écriture même s'il déclare le schéma
  (P44-D-02a)
- [x] **MOTR-05**: Le marqueur de clôture d'un plan est un fichier à côté de `PLAN.md`, qui n'est
  jamais modifié pour marquer la clôture (son hash reste stable) ; `à exécuter` = `PLAN.md`
  présent, marqueur absent (P44-D-03)
- [x] **MOTR-06**: Une liste fermée d'emplacements annexes nommés à la racine de `.planning/`
  (`_bancs/`, `recherches/`, `intel/`, `sketches/`, `_archive/`, `registres/`) est ignorée par le
  recalcul ; tout le reste qui n'est ni un emplacement du modèle ni un emplacement annexe est
  signalé « hors modèle » dans `INDEX.md` (signalé, jamais refusé, jamais déplacé) ; la liste vit
  dans le code et la référence du modèle, pas dans `config.json` (P44-D-04)
- [x] **MOTR-07**: Les huit états s'appliquent aux phases et aux plans ; l'état d'un cycle est une
  agrégation de ses phases (règle écrite dans la référence du modèle) ; les dérogations (`abandonné
  | remplacé | gelé`) sont lues dans un champ `statut:` qui doit nommer son auteur — une dérogation
  sans auteur rend `indéterminé` (P44-D-07)
- [x] **MOTR-08**: Toute combinaison de signaux non prévue rend `indéterminé`, jamais une
  supposition ; le banc couvre au minimum `SUMMARY.md` sans `PLAN.md`, `VERDICT.md` sans marqueur
  de clôture, `SUMMARY.md` avec un verdict en échec, marqueur sans `PLAN.md` (P44-D-08)
- [x] **MOTR-09**: Le recalcul lit les constats de `VERDICT.md` (passé / échec) pour dériver `à
  corriger` et `close` ; les champs `hash` et `tentative` sont lus s'ils sont présents, sans être
  vérifiés (leur vérification relève de la Phase 46) (P44-D-09)
- [x] **MOTR-10**: `INDEX.md` (par cycle : état dérivé, phase courante, dernier signe de vie,
  bail en cours toujours « aucun » en 44, liste des entrées hors modèle) et `STATE.md` (position
  courante) sont générés de façon déterministe : deux recalculs sur le même disque produisent des
  fichiers identiques octet pour octet (P44-D-10)
- [x] **MOTR-11**: `cloture.log` est append-only : le recalcul ajoute une ligne quand il observe
  l'entrée d'une phase ou d'un plan en `close` (ou en dérogation), datée au moment de l'observation
  et signalée comme telle, jamais une ligne réécrite ou supprimée, format conforme (horodatage ISO
  avec fuseau, chemin, auteur, verdict), auteur résolu sans git (P44-D-11)
- [x] **MOTR-12**: Le recalcul est écrit en Python 3.9+, bibliothèque standard seule (pas de
  PyYAML, parser de frontmatter minimal écrit pour le modèle), aucune logique de recalcul en bash
  (P44-D-12)
- [x] **MOTR-13**: Le recalcul est incrémental par hash du contenu, jamais par `mtime` ; un cache
  absent, illisible ou d'un autre format provoque un recalcul complet, jamais une confiance
  aveugle ; preuve au banc dans les deux sens (un `touch` sans changement de contenu ne change
  rien ; un changement de contenu à `mtime` restauré est vu) (P44-D-13)
- [x] **MOTR-14**: Le recalcul est livrable par l'installeur existant sans modification de ses
  sites de pose (Python embarqué dans un `.sh`, motif `plugin/conductor/scripts/dag.sh`), sauf si
  le plan motive et documente le choix de l'extension à `*.py` sur tous les sites de l'installeur
  (P44-D-14)
- [x] **MOTR-15**: Aucun hook ni gate n'est câblé dans cette phase : le recalcul est une commande
  autonome, sans protection des fichiers générés contre l'écriture à la main (P44-D-15)
- [x] **MOTR-16**: Les suites de test bash sous `plugin/planning-core/scripts/tests/` et les
  fixtures du banc synthétique versionné couvrent les huit états, chacun avec son jumeau négatif,
  et chaque garde est prouvée par une mutation rouge avec sa trace (assertion, attendu, obtenu) ;
  les commandes de boucle rejouent sous zsh et bash avec au moins deux éléments (P44-D-17)
- [x] **MOTR-17**: Un banc synthétique versionné dans le dépôt couvre les huit états, les
  dérogations et les contradictions rendant `indéterminé`, et gate seul en CI ; un passage en
  lecture seule, hors CI, mesure le temps et le nombre d'`indéterminé` sur deux labs réels du poste
  sans y écrire (empreinte sha256 avant/après comparée octet par octet), chemins machine-locaux
  jamais dans le code livré ni une suite de CI (P44-D-06, P44-D-06a, P44-D-06b)
- [x] **MOTR-18**: `plugin/planning-core` reçoit un bump de version mineur (nouvelle capacité),
  CHANGELOG et README du module mis à jour ; aucune release du jalon gouvernance (pas de bump de
  la `VERSION` racine, pas de tag) avant la clôture de `fiabilite-v1.0` (P44-D-18)
