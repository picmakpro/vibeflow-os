# CHANGELOG — consolidator

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
