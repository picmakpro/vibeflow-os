---
quick_id: 260928-vk9
status: complete
date: 2026-09-28
---

# Summary — garde de lecture du détecteur, lot 8 (correction de CLASSE), Phase 44

Mandat vf-coder, mission `mgr-44-reprise`, nœud `exec-44` rouvert, mode autonome, CORRECTION
MINIMALE. Dernier lot : pas de nouveau tour de juges après celui-ci — la preuve repose entièrement
sur les tests rouge→vert et sur le verdict `gsd-verifier`. Décision du head sous délégation
technique de Willy, session principale, 2026-09-28 : option (a), lot 8 minimal, avec conditions de
test explicites (voir mandat).

## Ce qui a été fait

**Commit `0c284e3`** :

- **`plugin/planning-core/scripts/recalc-planning.sh`** :
  1. `_lecture_detecteur_fidele` — les deux sites qui jugent la présence d'un `STATE.md` (racine et
     de compartiment) utilisent désormais `os.path.isfile`, mirroir EXACT de `[ -f ]` que lit le
     détecteur (`detect-gsd-engine.sh:96,184` : suit le lien, exige un fichier RÉGULIER à la
     cible), au lieu de `os.path.lexists` (vrai même pour un lien cassé). Un lien symbolique CASSÉ
     (cible absente) est désormais traité comme ABSENT — comme pour le détecteur — jamais un refus
     « illisible ». Le `STATE.md` racine en lien cassé reste TOUJOURS refusé, mais PAR AILLEURS
     (garde B de `appliquer_ecritures`, « emplacement occupé », F4, `lstat` sans jamais suivre le
     lien) — jamais un double refus, jamais d'écriture à travers le lien.
  2. `_ouvrable` — branche fichier durcie : ouverture en `O_RDONLY | O_NONBLOCK` puis `fstat` du
     descripteur exigeant `S_ISREG` (refus nommé sinon). Sans cela, un `STATE.md` en FIFO bloquait
     le processus INDÉFINIMENT (mesuré, aucune borne). Note : le correctif 1 (`os.path.isfile`
     avant l'appel) suffit déjà, seul, à empêcher que `_ouvrable` soit appelée sur une FIFO depuis
     les deux sites d'appel actuels (`[ -f ]` est aussi faux sur une FIFO) — le durcissement
     `O_NONBLOCK` est une défense en profondeur de `_ouvrable` elle-même, exercée directement au
     niveau unitaire par la suite de tests (contournant volontairement ce gate), pour tout appel
     futur qui ne passerait pas par lui.
  3. Correction de prose (revue, mineur) : le commentaire de tête disait que les classes
     structurelles du lot 6 « ne décident jamais seules » — en réalité elles sont fusionnées dans
     la MÊME liste de décision que l'égalité d'ensembles et la lisibilité réelle
     (`len(vues) == 0`) : n'importe laquelle des trois, seule, suffit à refuser. Prose corrigée
     pour dire exactement ce que fait le code.
- **`plugin/planning-core/scripts/tests/test-recalc-planning.sh`** — section « Lot 8 » (10
  assertions nouvelles, 303 → 313 OK) :
  - `R-LOT8-LIEN-CASSE-COMPARTIMENT` : lien cassé de compartiment, AUCUN marqueur GSD nulle part →
    écriture autorisée (rc=0). ROUGE sur HEAD `345303e` (rc=3, « garde de lecture », sur-refus).
  - `R-LOT8-LIEN-CASSE-RACINE` : lien cassé RACINE → TOUJOURS refusé, mais par la garde B
    (rc=1, « emplacement occupé »), cible du lien jamais créée. ROUGE sur `345303e` (rc=3, «
    garde de lecture » — mauvaise raison, la garde B n'est même pas atteinte).
  - `R-LOT8-FIFO-RACINE` / `R-LOT8-FIFO-COMPARTIMENT` : `STATE.md` en FIFO, racine et compartiment
    → refus/écriture RAPIDE (bornés à 6 s via `subprocess.run(timeout=…)`, ce poste n'a ni
    `timeout` ni `gtimeout`), jamais de blocage. ROUGE sur `345303e` : blocage confirmé au-delà de
    6 s dans les deux cas.
  - `R-LOT8-OUVRABLE-FIFO` : `_ouvrable` appelée DIRECTEMENT sur une FIFO (contourne le gate
    `os.path.isfile`, jamais atteint depuis les deux sites d'appel avec le correctif 1 — défense en
    profondeur exercée quand même, au niveau unitaire, via `multiprocessing` en contexte `fork`
    explicite : ce poste est macOS, dont le défaut `spawn` re-exécute le module `__main__`).
    RAPIDE, refus nommé (`False`). ROUGE sur `345303e` : blocage confirmé.
  - `MUT-LOT8-ONONBLOCK` : `O_NONBLOCK` retiré → la FIFO bloque à nouveau, tué PAR LE DÉLAI (6 s),
    sans pendre la suite (le sous-processus est dans un `multiprocessing.Process` séparé, `.join`
    borné puis `.terminate()`).
  - `R-LOT8-TEMOIN` (témoin, oracle différentiel, x2 : avec/sans marqueur) : `STATE.md` de
    compartiment en lien vers un fichier régulier interne — le verdict du moteur égale TOUJOURS
    celui du détecteur réel lancé directement. Déjà vert sur `345303e` (non-régression) : ces deux
    cas ne traversent aucun des deux chemins buggés.
  - `MUT-LOT8-LIEN-CASSE-COMPARTIMENT` / `MUT-LOT8-LIEN-CASSE-RACINE` : `os.path.isfile` reverti à
    `os.path.lexists` (motif fixe unique, patron `make_recalc_mutant`) → sur-refus (compartiment)
    ou diagnostic divergent (racine, rc=3 « garde de lecture » au lieu de rc=1 « emplacement
    occupé ») — tués tous les deux.
  - Note méthode : `rouge sur 345303e` prouvé en substituant TEMPORAIREMENT
    `recalc-planning.sh` par `git show 345303e:...` (siblings `detect-gsd-engine.sh`/
    `workstream-policy.sh` copiés inchangés à côté, `SCRIPT_DIR` les résout), suite complète
    rejouée (305 OK/8 KO — les 8 KO sont exactement les 8 assertions directes du lot 8, les 2
    témoins et les 2 mutants motif-absent ne comptent pas comme rouge attendu), puis restauration
    octet pour octet (`cmp -s`) avant de committer.
- **Documentation** : `plugin/planning-core/references/modele-cycles.md` (section « Lien cassé =
  absent, FIFO refusée sans blocage », § Résidus acceptés — TOCTOU garde/détecteur mesuré 1/15 par
  `mv` concurrent, coût à volume ~98 s/3000 compartiments, citation de la décision), CHANGELOG
  v2.8.0 (entrée « Lot 8 » sous l'entrée existante, AUCUN bump de version). `.planning/BACKLOG.md` :
  entrée existante pour Samuel (`vf_ws_enumerate`) complétée d'un paragraphe « Coût à volume et
  fenêtre TOCTOU, mesurés lot 8 » — aucun chemin absolu de machine.

## Vérifications rejouées

- `test-recalc-planning.sh` : 313 OK / 0 KO (~52 s à chaud, ~175 s à froid sur la première passe).
  Aucun blocage : durée totale mesurée à chaque exécution.
- 8 suites sœurs (`test-check-planning-state.sh`, `test-detect-gsd-engine.sh`,
  `test-detect-planning-debt.sh`, `test-planning-context-hardening.sh`, `test-planning-core.sh`,
  `test-planning-hooks.sh`, `test-workstream-policy.sh`, `test-workstream-symlink-escape.sh`) :
  toutes vertes, 0 échec.
- `git diff --stat 424cb23..HEAD -- plugin/planning-core/scripts/detect-gsd-engine.sh
  plugin/planning-core/scripts/workstream-policy.sh` : VIDE (octet pour octet inchangés).
- Sonde PY39 (`ast.parse(feature_version=(3,9))` sur le corps extrait) : OK.
- Sonde `CONTRAT-CROISE` (référence ↔ moteur, 42 jetons) : `CONTRAT-CROISE-OK 42 / 42`.
- `check-machine-paths.sh` (rejoué APRÈS le commit) : ✓ aucun chemin absolu de machine.
- `check-version-sync.sh` : ✓ sources synchronisées (aucun bump).
- `check-planning-consumers-registered.sh` : ✓ 21 consommateurs recensés.
- `check-gate-touche.sh` : RIEN-A-JUGER (aucun chemin de la surface surveillée touché entre
  `424cb23` et HEAD).

## Périmètre respecté

Fichiers touchés strictement limités aux quatre nommés dans le mandat, `.planning/BACKLOG.md`, et
cet artefact quick. `detect-gsd-engine.sh`, `workstream-policy.sh`, les autres suites,
`plugin/dev-orchestrator/**`, `plugin/conductor/**` (hors appel de `driver-lock.sh`), gsd-core,
`.github/**`, `scripts/**` (hors lecture des gates), `VERSION`, `README*.md`, le compartiment
`fiabilite`, `.planning/ROADMAP.md`, `.planning/missions/**`, `.claude/agent-memory/**` : AUCUN
touché. Le `STATE.md` du compartiment `gouvernance` sera mis à jour à la main, jamais via
`state.*`.
