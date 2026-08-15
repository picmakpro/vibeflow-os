# CHANGELOG — consolidator

## [v1.10.0] — 2026-08-16 (Portabilité Windows II — codes de sortie, PORT-03/D-07)

### Changé
- **`check-registres.sh` et `seed-registres.sh` traduisent leur silence interne vers 0 sous
  `--hook`**, même patron (`hook_exit`) que le périmètre dev normalisé au plan `VFDO-30-04`.
  `check-registres.sh` portait déjà le drapeau ; `seed-registres.sh` le gagne (parité
  d'interface), avec la mutuelle exclusion `--hook`/`--quiet` (exit 64). Sans `--hook`, aucun
  code ne change.
- **Correctif au passage** : `check-registres.sh --strict --allow-empty` sortait
  INCONDITIONNELLEMENT en 3 avec un message sur stdout, même sous `--hook` — ce chemin n'était
  encore jamais passé par la garde `--hook` du tout. Il l'est désormais (stdout strictement vide
  sous `--hook`, message inchangé sans `--hook`).

Voir `docs/HOOKS-CONTRAT-SORTIE.md` pour le contrat complet.

## [v1.9.0] — 2026-08-15

### Changé
- **`mandatory: true` — le module passe en baseline du lab (INST-02a).** La capitalisation est le
  principe 1 de VibeFlow (« le projet n'oublie jamais », `patterns/06-capitalisation.md`) ; le socle
  qui la porte cesse de dépendre d'une arête transitive pour arriver dans un lab. Le module était
  déjà entraîné en pratique par `conductor` → `validator` → `consolidator`, mais **indirectement** :
  retirer `validator` d'un lab emportait silencieusement sa mémoire. `mandatory` en fait un invariant
  déclaré, indépendant de la topologie des `requires`.
- **Rattrapage automatique des labs existants** : `ensure_mandatory_baseline` (data-driven, aucun
  nom de module en dur) installe la fermeture transitive de tout module `mandatory` absent au
  prochain `update --all`. Même mécanisme que le rattrapage de `conductor` en v2.7.0.
- **Description du catalogue corrigée** : elle annonçait « 4 piliers » alors que le pilier 5
  (mémoire vivante, ADR-052) est livré depuis v1.6.0, et ne mentionnait ni les registres ni la
  gouvernance par hooks — c'est pourtant ce que l'utilisateur cherche quand il parle de « mémoire ».

### Corrigé — la mémoire arrive enfin toute seule
- **`seed-registres.sh` : les gabarits sont désormais instanciés, plus seulement posés.** C'était le
  vrai défaut, mesuré sur pièce le 2026-08-15 : après installation de la baseline dans un dépôt
  vierge, `consolidator` était bien posé, ses hooks bien câblés, ses 5 gabarits bien déposés sous
  `skills/consolidator/references/templates-memoire/` — mais `.claude/memory/` **n'existait pas** et
  `check-registres.sh --strict` sortait en rc=1 avec les 5 registres canoniques manquants. Aucun
  script n'allait chercher ces gabarits. La machinerie mémoire tournait à vide sur un dossier
  inexistant, et c'est ce qui produisait le symptôme terrain « ma logique mémoire n'est pas là »,
  bien plus que la question de savoir quel module était installé.
- **Transparent à l'install ET à l'update.** Le seeder est appelé par un quatrième hook post-install
  nommé dans l'engine (patron des 3 existants) **et** par `sync_module_governance`, c'est-à-dire
  aussi sur le chemin « module déjà à jour » que prend `update --all`. Sans ce second point d'appel,
  un lab configuré avant cette version n'aurait reçu ses registres qu'au prochain bump du module —
  soit jamais s'il n'évolue plus. Un utilisateur existant n'a donc aucun geste à faire.
- **Non destructif, par contrat et par test.** Le script ne sait que **créer ce qui manque** : un
  registre existant n'est ni écrasé, ni fusionné, ni réordonné (les registres sont append-only et
  portent l'historique réel du lab). Vérifié par empreinte dans `test-seed-registres.sh` T3/T4, pas
  seulement par présence de fichier. Idempotent, donc sûr à rejouer à chaque install et update.
- **Data-driven** : la liste des registres sort des gabarits présents (`*-template.md` → `<NOM>.md`),
  aucun nom en dur — ajouter un 6e registre au module suffit à le faire poser (test T10).
- **Scope `user` : chaque projet a enfin SA mémoire (`--project` + hook `SessionStart`).** Le hook
  post-install seul ne pouvait pas suffire, et le trou était franc : en scope user les scripts vivent
  dans `~/.claude/`, donc le seeder remplissait `~/.claude/memory/` — la mémoire du compte — pendant
  que `check-registres.sh` et les guards de lecture résolvent `.claude/memory` **relativement au
  cwd**, c'est-à-dire dans le projet ouvert. Résultat mesuré : le home rempli, chaque projet vide, et
  le lint rouge dans tous les projets d'un poste où VibeFlow est pourtant installé. Une install ne
  peut pas connaître à l'avance les projets qui l'utiliseront ; l'ouverture de session, si. Le mode
  `--project` cible le lab courant et est appelé à chaque `SessionStart` : la mémoire arrive dans
  chaque projet, sans geste, quel que soit le scope.
- **Garde du mode `--project`** : le cwd n'est traité comme un lab que s'il porte déjà `.planning/`
  ou `.claude/`. Un dépôt git quelconque ouvert au passage n'en fait délibérément pas partie — sans
  cette garde, le hook déposerait 5 fichiers dans le premier dossier venu (test T14). Hors lab, sortie
  0 silencieuse : un non-événement, pas une anomalie.
- **Échappatoire `VF_NO_AUTO_SEED`** : coupe l'instanciation automatique de session sans désinstaller
  le module ni éditer un hook (test T15). Le geste reste non destructif dans tous les cas — le hook
  tourne à chaque ouverture de session et ne sait toujours que créer ce qui manque (T16).
- **Cloisonnement vérifié** : deux labs distincts ont deux mémoires distinctes, sans fuite de l'un
  vers l'autre (T17) — l'invariant que le scope user cassait en silence.
- **Le trou de CI est fermé.** Le job « lab frais » passait `--allow-empty`, qui convertit
  « 5 registres canon manquants » (rc=1) en « lab vierge, indéterminé » (rc=3), puis acceptait
  rc=3 : la CI validait un lab **sans mémoire** en le prenant pour un lab neuf. Elle exige désormais
  le vert dur, plus `seed-registres.sh --check`. Sa baseline cesse aussi de coder `conductor` en dur
  et se dérive des modules `role=mandatory` du catalogue.

### Décidé — MemPalace reste éteint (capability GSD)
- Vérifié le 2026-08-15 : **ni la CLI `mempalace` ni un serveur MCP `mempalace_*` ne sont
  disponibles** sur le poste. Activer `mempalace.enabled` insérerait 7 étages dans le cycle
  (`discuss:pre/post`, `plan:pre/post`, …) qui résoudraient leur wing, tenteraient leur transport,
  échoueraient et rapporteraient « unavailable » — un coût en tokens à chaque phase pour un bénéfice
  nul. La frontière était déjà tranchée par `check-overlaps.sh` : `consolidator` = canon mémoire de
  lab in-repo et machine-enforced ; `mempalace` = opt-in, non activé, non répliqué.
- **Déclencheur de reprise** : le jour où MemPalace est réellement installé (CLI ou MCP). Son apport
  propre est le *recall sémantique* — retrouver « requests hang under load » depuis « API times out
  when many users connect », là où l'appariement par mots-clés échoue — et il est orthogonal aux
  registres, pas redondant. Il ne devient intéressant qu'une fois les registres réellement remplis :
  l'activer sur un lab qui n'en avait aucun aurait été mettre la charrue avant les bœufs.

### Note de migration
- `consolidator` ne se retire plus à l'unité (règle des modules `mandatory`, cf. `installer/SKILL.md`
  §Désinstallation) : il ne part qu'avec `uninstall --all`.

## [v1.8.1] — 2026-07-27

### Corrigé
- `check-registres.sh` : flag `--allow-empty` implémenté (il était appelé par le job CI « Lab frais » mais rejeté en « arg inconnu » → rc=1). En `--strict --allow-empty`, un lab VIERGE (aucun registre) rend exit 3 (verdict INDÉTERMINÉ ≠ vert, doctrine F13) au lieu de 1 ; présence partielle → exit 1 inchangé. Tests T11a/b/c ajoutés.

## [v1.8.0] — 2026-07-26

### Ajouté
- Templates de registres embarqués (`references/templates-memoire/`, 5 templates posés à l'install — un lab frais n'a plus à rétro-dériver le format canonique, F1 UAT). Corrigé : `reindex.sh` comptages normalisés sur registre vide (F7) ; strays legacy `*.bak-reindex-*` rapatriés dans `.backups/` (F8).

## [v1.7.0] — 2026-07-25

### Ajouté
- `check-registres.sh --strict` proportionné au profil : EVALS absent = warning en profil léger (exigé sinon). Cadences reformulées : à la release / au jalon (labs solo), mensuel/trimestriel (labs d'équipe actifs).

## [v1.6.2] — 2026-07-25

### Corrigé
- Références `/checkpoint` (commande inexistante) → `/vf-audit` ; `probe-memory-guards.sh` vérifie désormais le câblage réel des 3 gardes (+ mode `--strict`).

## [v1.6.1] — 2026-07-23 (portabilité Windows — ADR-054, 2e rapport terrain)

### Corrigé
- **Préfiltres CSL-13 aveugles aux antislashs** (`guard-read-registres.sh`, `guard-bash-registres.sh`,
  `post-edit-reindex.sh`) : le match `.claude/memory/` (slashes) court-circuitait le python — qui,
  lui, normalisait les antislashs (CSL-12) — dès qu'un chemin Windows arrivait (`.claude\\memory\\`,
  JSON-échappé). Gardes et réindexation inertes sous Windows en paraissant installées. Motifs
  antislashs (simple + JSON-échappé) ajoutés ; le python reçoit toujours le payload original.
- **Stub Microsoft Store `python3`** : présent dans le PATH (`command -v` réussit) mais inerte —
  le repli fail-open n'était jamais atteint. Résolution d'interpréteur par CHEMIN (zéro spawn
  ajouté, rejet `WindowsApps`, repli `python`) dans les 3 hooks + `reindex.sh` (qui, sans
  interpréteur, échoue désormais BRUYAMMENT au lieu d'un silence).
- **`post-edit-reindex.sh`** : normalisation des antislashs du `file_path` extrait — sans ça, le
  filtre parent/base ne matchait jamais un chemin Edit/Write Windows et l'index n'était pas recalé.

### Ajouté
- **`probe-memory-guards.sh`** (hook SessionStart, advisory) : UNE sonde d'exécution réelle par
  session dans l'environnement RÉEL des hooks — si aucun Python utilisable : « ⚠ gardes mémoire
  INACTIVES ». Suggestion du rapport terrain adoptée telle quelle : une protection annoncée n'est
  pas une protection tant qu'un refus n'a pas été observé ; à défaut, l'inactivité doit se voir.
- `tests/test-windows-guards.sh` : payload antislashs → deny effectif · stub WindowsApps → repli
  `python` · aucun interpréteur → fail-open + signal du probe.

## [v1.6.0] — 2026-07-22 (ADR-052 — pilier 5 : mémoire vivante à décroissance + supersession)

### Ajouté
- **Pilier 5 — Mémoire vivante** : nouvelle couche mémoire **fichier-par-entrée**
  (`.claude/memory/knowledge/`, format frontmatter natif Claude Code), distincte des registres d'audit
  tabulaires (piliers 1-4, **inchangés**). Porte le savoir vivant du lab (user/feedback/project/reference),
  dont la fiabilité décroît dans le temps.
- `scripts/decay-pass.sh` : passe idempotente `--dry-run`/`--apply` qui applique les **3 gestes** ADR-052 —
  `trust` normalisé, `confidence` base préservée + `effective_confidence` recalculée par demi-vie de
  catégorie (`feedback` 365 / `user` 180 / `reference` 120 / `project` 30 j), et supersession **non
  destructive** (`superseded_by` → déplacement vers `archive/`, jamais de suppression — ADR-031). Seuil de
  rétrogradation `needs_review` (défaut `effective_confidence < 0.2`) = flag, jamais suppression. Backups
  isolés ADR-049 avant `--apply`.
- `scripts/tests/test-decay.sh` : 27 tests (dry-run sans effet de bord, base préservée, idempotence,
  supersession non destructive, hygiène/backups/no-op, + régressions de revue : listes YAML préservées,
  archive homonyme jamais écrasée, date future bornée).

### Durci (revue de code)
- **Archive non écrasante** : une supersession vers un slug déjà présent dans `archive/` ne détruit plus
  l'archive existante — la nouvelle est suffixée `.superseded-<ts>.md` (garantie ADR-031 renforcée).
- **Préservation non lossy** des blocs YAML inconnus (listes, mappings) : réémis verbatim au lieu d'être
  corrompus en `key: value`.
- **Bornage** : `age` ≥ 0 et `effective_confidence` ∈ [0,1] — une date `created` future ne gonfle plus la
  confiance. Normalisation CRLF/BOM avant parse. Réparations (trust/confidence/created invalides) tracées
  en `warnings`.
- Template de format `templates/memory/knowledge-entry-template.md` (+ miroir `plugin/reference/`) et
  référence `references/memoire-vivante.md`.
- `/consolidate --pillar=decay` + Phase 6 dans l'orchestration.

### Note
- La décroissance est **batch** (au `/consolidate`), pas par-tour : Claude Code n'expose pas de hook
  par-tour fiable (pipeline par-tour de jcode explicitement différé). `reindex.sh`/`archive.sh` ne sont
  pas modifiés (couplés au format tabulaire).

## [v1.5.0] — 2026-07-20 (audit robustesse hooks — 16 findings corrigés, 2 pertes de données évitées)

### Corrigé — intégrité des données
- **`reindex.sh` : perte de body silencieuse** (CSL-01) — un registre avec `## Index` sans `---` de
  fermeture voyait tout son body détruit par `--apply` (déclenché automatiquement par le hook
  PostToolUse, backups rotationnés en 3 éditions → perte définitive). Pré-garde fail-open : sans
  terminateur, la réécriture est ANNULÉE + check C1bis dans check-registres.
- **`archive.sh` : doublons systématiques** (CSL-02) — chaque SessionEnd ré-appendait les mêmes
  entrées dans `archive/` (1→2→3 démontrés). Garde d'idempotence par ID avant append.
- **`reindex.sh` : `#Ligne` faux après chaque append** (CSL-08) — les positions étaient extraites
  avant réécriture ; l'insertion décalait le body → tout l'édifice index-first pointait à côté.
  2e passe de recalage convergente ; test : chaque `#Ligne` == position `grep -n` réelle.
- **`reindex.sh` : lost update en concurrence** (CSL-09) — 2 sessions simultanées → un body
  définitivement perdu (démontré). Verrou `mkdir` atomique (stale 60s), skip silencieux si occupé.

### Corrigé — faux positifs des guards (lecture/écriture registres)
- `guard-bash-registres.sh` : `grep -n 'open' <registre>` et tout motif valant un lecteur (cat,
  view…) était DENY (CSL-04) → matching en position de commande uniquement ; le contenu des
  heredocs n'est plus analysé (documenter la règle ne la déclenche plus, CSL-05) ; cible
  d'écriture quotée `>> "<registre>"` n'est plus bloquée (CSL-06).
- `post-edit-reindex.sh` : symétrique — l'écriture quotée déclenche bien le reindex désormais
  (CSL-07) ; filtre parent corrigé (`*.claude/memory` ne matche plus `my.claude/memory`, CSL-12).
- `guard-read-registres.sh` : `os.path.normpath` + comparaison de parent exacte (CSL-12),
  traversée `archive/../` fermée.

### Corrigé — cycle de vie & performance
- **`archive.sh --async` était un flag mort** (CSL-03) : SessionEnd synchrone, 92s mesurés sur gros
  lab → tué par le timeout hook 60s (archive partielle + lock fuité). Vrai async : re-exec nohup +
  disown, exit 0 immédiat, garde anti-refork. Verrou mkdir atomique + trap quoté (CSL-14) ;
  compteur exact, `[ -d memory ] || exit 0` anti-pollution, rotation du log (CSL-15).
- C3 (références récentes) cumule désormais `ITERATION_LOG.md` ET `JOURNAL.md` — les labs canon
  DECISIONS/JOURNAL n'archivaient plus sur un critère aveugle (CSL-10).
- Préfiltre pur-bash avant python3 sur les 3 hooks par-appel : ~24ms vs ~100ms sur le chemin
  hors-registre, surensemble strict justifié en commentaire (CSL-13).
- `hooks/hooks.json` : `|| true` sur le seul PostToolUse (install cassée = silence, pas du bruit
  à chaque Edit/Write/Bash) ; les 2 PreToolUse bloquants restent sans (CSL-11).
- `check-registres.sh` : bornes C1/C2 portées à 200 lignes (gros préambules), C2 cherche `#Ligne`
  après `## Index` en awk sans pipe (CSL-16).

### Tests
- 4 suites, 84 checks, 100% PASS sous /bin/bash 3.2 : test-consolidator 40/40,
  test-guard-bash-registres 20/20, test-guard-read-registres 14/14, test-check-registres 10/10.
  Repro contre-validée sur les versions HEAD (CSL-01/02/08 reproduits avant fix).

## [v1.4.0] — 2026-07-16 (ADR-049 — backups mémoire isolés + rotation intégrée)

### Corrigé
- `reindex.sh --apply` : les backups ne polluent plus `.claude/memory/` (14 fichiers / 1,6 Mo mesurés
  dans un lab réel, dont 8 committés). Ils sont désormais **isolés dans `.claude/memory/.backups/`**
  avec un **`.gitignore` auto-suffisant** (`*` + `!.gitignore`) → jamais committés, sans config du lab.
- **Rotation intégrée dans `reindex.sh`** (garde N derniers, défaut 3, `VF_BACKUP_KEEP`) → **tout**
  `--apply` purge, plus seulement le hook `post-edit-reindex.sh` (dont la rotation dupliquée est retirée).
- Portabilité : rotation en bash 3.2 (macOS) — pas de `mapfile`.

### Tests
- `test-consolidator.sh` T7 (isolation racine / rotation 3 / gitignore auto). 17 tests au total.

## [v1.3.1] — 2026-07-05 (BLK-007 — fenêtre de lecture bornée par VALEUR)

### Corrigé
- `guard-read-registres.sh` — la v1.2.0 autorisait dès qu'`offset` OU `limit` était PRÉSENT :
  `Read(offset=1)` sans limit (ou `limit=100000`) lisait tout le registre (contournement
  terrain, 2e faille après BLK-006). Règle resserrée : lecture d'un registre > 150 lignes
  autorisée UNIQUEMENT si `limit` est fourni ET ≤ `VF_GUARD_MAX_READ` (défaut 60, surchargeable).
  Un guard valide les VALEURS des paramètres, jamais leur présence.

### Tests
- test-guard-read-registres : +3 (offset seul → deny ; limit=100000 → deny ; frontière 60/61).


## [v1.3.0] — 2026-07-05 (BLK-006 — contournement shell fermé)

### Ajouté
- `guard-bash-registres.sh` — hook PreToolUse(Bash) : le guard Read seul ne protégeait que le
  chemin nominal (contournement terrain : `cat .claude/memory/DECISIONS.md`). DENY des lectures
  pleines shell (cat/less/more/bat/nl/tac/vi…, head/tail non bornés) d'un registre > 150 lignes ;
  lectures ciblées (grep, sed -n plage, head ≤ 150), pipelines limités en aval (`cat X | head -20`)
  et écritures (`>>`, tee) restent libres. Limite assumée : interpréteurs inline (python -c) non
  couverts — garde-fou déterministe contre le chemin de moindre résistance, pas une sandbox.

### Modifié
- `post-edit-reindex.sh` — couvre le tool Bash : un append shell (`cat >> DECISIONS.md`, `tee -a`)
  recale aussi l'index (matcher PostToolUse étendu à `Edit|Write|Bash`).
- `hooks/hooks.json` — + matcher Bash (guard) ; PostToolUse `Edit|Write` → `Edit|Write|Bash`.
- Engine `merge-hooks.sh` : dédup cross-matcher au merge — un upgrade qui change le matcher d'un
  hook (ex. `Edit|Write` → `Edit|Write|Bash`) purge l'ancien groupe au lieu de dupliquer l'exécution.

### Tests
- `test-guard-bash-registres.sh` (14 : guard 12 + post-edit Bash 2) ; test-merge-hooks + T7 (upgrade matcher).


## [v1.2.0] — 2026-07-04 (ADR-043 — gouvernance scripturale)

### Ajouté
- `guard-read-registres.sh` — hook PreToolUse(Read) : DENY toute lecture d'un registre canonique
  sans offset/limit au-delà de 150 lignes. L'Iron Law index-first est machine-enforced.
- `check-registres.sh` — lint format (## Index + #Ligne, cohérence index↔body, doublons).
  Modes `--strict` (gate init vf-new-lab Gate C) / `--hook` (SessionStart informatif).
- `post-edit-reindex.sh` — hook PostToolUse(Edit|Write) : reindex --apply automatique du registre
  édité + rotation des backups (3 max). L'index ne dérive plus.
- `hooks/hooks.json` — les 4 hooks (guard-read, post-edit-reindex, check-registres, archive
  SessionEnd) sont MERGÉS AUTOMATIQUEMENT dans `.claude/settings.json` à l'install (merge-hooks.sh).

### Modifié
- `reindex.sh` — bootstrap : crée le bloc `## Index` s'il est absent (registre v1/sortie d'init),
  avec 2e passe pour recaler les #Ligne. Avant, --apply était silencieusement sans effet.
- `detect-duplicates.sh` — couvre désormais DECISIONS.md (gap).
- Canon DECISIONS.md/DEC-XXX dans SKILL/README/références ; spec index alignée sur reindex.sh
  (5 colonnes, sans Tags) ; note obsolète « PreToolUse(Read) pas supporté » corrigée (le deny EST
  supporté — vérifié doc Claude Code 2.1.201).

### Tests
- `test-guard-read-registres.sh` (8), `test-check-registres.sh` (8) + non-régression 14/14.

## [v1.0.0] — 2026-05-24

### Initial release

**Pilier 1 — Indexation**
- Convention `index header` avec colonne `#Ligne` strict
- Iron Law : "Lecture d'un registre = lecture de l'index uniquement par défaut"
- Script `reindex.sh` (modes `--audit`, `--dry-run`, `--apply`)
- Mode `--apply` préserve Date + Resume + orphelins (LRN-106 régression résolue Session 047)

**Pilier 2 — Archivage**
- Script `archive.sh` avec 3 critères AND (statut RESOLU/OBSOLETE/SUPERSEDED + age > 90j + 0 ref récente)
- Support accents français (`RÉSOLU`, `Différée`, `Dépréciée`...)
- Support champ `**Date ouverture** :` en plus de `**Date** :`
- Hook `SessionEnd` async pour archivage non-bloquant
- Allowlist `.claude/scripts/archive.allowlist` pour protéger entrées fondatrices
- Lock file 5min TTL pour race conditions sessions parallèles

**Pilier 3 — Fusion**
- Script `detect-duplicates.sh` (collisions IDs + similarité titres Jaccard)
- Skill manuel `/consolidate --pillar=fusion` (LLM-based, pas embeddings ML)
- Pattern inspiré Anthropic Auto Dream + grandamenium/dream-skill

**Pilier 4 — Promotion**
- Script `detect-promotions.sh` (operational keywords + frequency clusters)
- Skill manuel `/consolidate --pillar=promote` semi-auto
- Iron Law : aucun write dans `.claude/rules/*.md` sans validation humaine (ADR-031)

**Suite de tests**
- `scripts/tests/test-consolidator.sh` — 14 tests, 100% pass
- Fixtures synthétiques `LEARNINGS-mini.md` + `BLOCKERS-mini.md`
- Tests de régression LRN-106 inclus (préservation orphelins)

**Documentation**
- `SKILL.md` (449 lignes, charte ADR-029 ≤500L)
- 4 références : indexation / archivage / fusion / promotion

### Validé en production
- Lab VibeFlow (cobaye) — Session 047 — 5 registres processés (ADR 32/31/1, LEARNINGS 106/74/32, BLOCKERS 5/5/0, EVALS vide, ITERATION_LOG 45)
- 3 collisions LRN-090/091 fusionnées
- BLK-005 dette pré-existante documentée

### Références
- ADR-032 (parent) — Système Consolidation Mémoire 4 piliers
- ADR-009 — Architecture mémoire tiered (parent historique)
- ADR-029 — Charte densité agents
- ADR-031 — Garde-fou support runtime
- LRN-105 — 4 piliers complémentaires
- LRN-106 — Audit avant fix (méta-learning Session 047)

### Limites connues v1.0.0
- ITERATION_LOG format Session (sans index) non géré (acceptable, format spécial)
- Compteurs JSON peuvent afficher "0\n0" cosmétiquement quand fichier vide (non bloquant)
- BLK-005 : 32 LRN orphelins (index sans body) préservés mais à compléter ultérieurement

## v1.1.0 — 2026-06-04

- reindex.sh : support BDR (registre fork BusinessFlow) dans les mappings par defaut + mecanisme de fork-config optionnel (`registers.conf.sh` sourced, surcharges `register_file_custom`/`id_pattern_custom`) — remontee BLK-005 point 4 du BFL.
- archive.sh : BDR.md ajoute a la liste des registres scannes.
- infrastructure-audit : whitelist Claude Code 2.1.162.
