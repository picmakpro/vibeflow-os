---
phase: VFDO-41-posture-de-protection-du-d-p-t
plan: 03
subsystem: docs
tags: [adr, claude-md, governance, github-rulesets, gitops]

# Dependency graph
requires:
  - phase: VFDO-41-posture-de-protection-du-d-p-t
    provides: "41-01 — accès admin constaté (D-02bis), sources JSON des deux rulesets écrites ;
      41-02 — CODEOWNERS étroit posé, ledger REQUIREMENTS.md amendé"
provides:
  - "ADR-072 amendée : sous-section « Amendement du 2026-09-23 — posture côté serveur (volet
    admin) » — contournement nommé D-02bis, politique hotfix, retour arrière, inconnus M-1..M-4,
    QUAL-01 ; statut d'index amendé"
  - "ADR-059 amendée : note datée du 2026-09-23 — « Branche pour tout travail de phase » devient
    la règle par défaut sur ce dépôt ; statut d'index amendé"
  - "CLAUDE.md : section « Protection côté serveur — main et tags v* » (avant « Gardes in-repo »),
    ouverture de « Gardes in-repo » corrigée (devenue fausse le 2026-09-23)"
affects: [41-04, 41-05, 41-06, 41-09, 41-10, 41-11]

# Actuals (#2632)
actuals:
  tokens: 14000
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Amendement d'ADR par sous-section blockquote datée (`> **ADR-NNN : amendement du <date>
      (Phase …)** — …`), jamais réécriture du texte antérieur — même discipline que l'amendement
      d'ADR-029 (Phase 40.1)"

key-files:
  modified:
    - docs/ADR.md
    - CLAUDE.md

key-decisions:
  - "L'amendement d'ADR-072 est placé en fin de la SECTION ADR-072 (juste avant `## ADR-073 :`),
    pas en fin de fichier : la PR #89 (mergée avant l'exécution de ce plan) a inséré ADR-073 après
    ADR-072, invalidant l'hypothèse « ADR-072 est la dernière section » sur laquelle le plan avait
    été écrit. Le placement retenu est le seul qui respecte le must_have « ajoutée en fin
    d'ADR-072 » sans intercaler du texte au milieu d'ADR-073 ni contredire ADR-073 (note de
    cohérence explicite ajoutée dans l'amendement). Voir Deviations."
  - "Aucune proposition de ce plan n'associe O-3 à un mot d'achèvement, même nié (balayage vert sur
    les deux fichiers, cf. verify)."
  - "PROT-02 et PROT-03 restent COCHÉS tels quels dans REQUIREMENTS.md (clôture du 2026-09-18, sous
    l'interprétation sans admin) — ce plan ne rouvre ni ne referme ces checkboxes : il enrichit la
    doctrine ADR-072/ADR-059/CLAUDE.md d'une couche admin cohérente avec la clôture existante,
    sans la remplacer ni y toucher (`requirements.mark-complete` n'a donc été invoqué pour aucun
    des deux IDs)."

requirements-completed: []  # PROT-03 et PROT-02 étaient déjà COCHÉS avant ce plan (clôture du
  # 2026-09-18, plans 41-17..41-19) — ce plan complète leur doctrine côté admin sans rouvrir leurs
  # checkboxes.

coverage:
  - id: D1
    description: "ADR-072 amendée : sous-section datée en fin de section (avant ADR-073), note
      d'amendement en tête, texte antérieur d'ADR-072 octet-identique, statut d'index amendé,
      autres lignes d'index intactes"
    requirement: PROT-03
    verification:
      - kind: other
        ref: "Task 1, bloc <automated> n°1 : termes_absents=0, index=1, statut_amende=1,
          autres_lignes_index_intactes=oui, amendement=1, note_d_amendement=1 — tous verts.
          derniere_adr=ADR-073 et historique_intact=non (au lieu de ADR-072/oui) : conséquence
          MÉCANIQUE de la présence d'ADR-073 (non prévue par le plan), pas un défaut de contenu —
          voir Deviations pour la preuve corrigée (historique_ADR-072_seul_intact=oui)"
        status: fail
      - kind: other
        ref: "Task 1, blocs <automated> n°2 (suppression/force push de main : 2/2) et n°3 (O-3,
          0 fichier en défaut)"
        status: pass
    human_judgment: true
    rationale: "Le sous-contrôle derniere_adr/historique_intact du bloc 1 suppose ADR-072 dernière
      section du fichier — hypothèse vraie à l'écriture du plan, invalidée par le merge de la PR
      #89 (ADR-073) AVANT l'exécution (fait signalé dans context_facts du dispatch). Le contenu
      requis (tous les termes, l'unicité de l'amendement, l'intégrité du texte antérieur) est
      prouvé par une vérification corrigée qui borne la comparaison à `## ADR-073` au lieu d'EOF —
      voir Deviations. Aucun correctif du script de vérification (hors périmètre déclaré de ce
      plan, potentiel Gate-Touche) : documenté, pas neutralisé (ADR-031)."
  - id: D2
    description: "ADR-059 amendée : note datée en fin de section (avant ADR-060), termes requis
      présents en blockquote, texte d'origine intact, statut d'index amendé"
    requirement: PROT-02
    verification:
      - kind: other
        ref: "Task 2, bloc <automated> n°1 : amendement=1, termes_absents=0,
          texte_d_origine_intact=oui, index_amende=1"
        status: pass
    human_judgment: false
  - id: D3
    description: "CLAUDE.md : section « Protection côté serveur — main et tags v* » insérée juste
      avant « Gardes in-repo », termes requis présents, ouverture fausse remplacée, « Limite de
      fond » intacte, « Discipline de release » (zone PR #87) octet-identique, au plus 2 lignes
      retirées au total du fichier"
    requirement: PROT-02
    verification:
      - kind: other
        ref: "Task 2, bloc <automated> n°2 : section_serveur=1, section_suivante=gardes_in_repo,
          termes_absents=0, ouverture_fausse_restante=0, limite_de_fond=1,
          discipline_de_release_intacte=oui, lignes_retirees=2"
        status: pass
    human_judgment: false
  - id: D4
    description: "Recensement de fermeture (`check-aucune-fermeture.sh`) rc=0 sans hit ; balayage
      O-3 (CLAUDE.md, docs/ADR.md) vert"
    verification:
      - kind: other
        ref: "Task 2, blocs <automated> n°3 et n°5 : perimetre=31 fichiers, allowlist 3/3,
          limite 11/11 manquants=aucun, hits=0 ; o3 fichiers_en_defaut=0"
        status: pass
    human_judgment: false
  - id: D5
    description: "Rejeu `gates` intégralement vert (aucun rouge, y compris le rouge STATE.md du
      plan 41-02, corrigé entre-temps par l'orchestrateur)"
    verification:
      - kind: integration
        ref: "replay-ci-jobs.sh --job gates : rc=0, 14 rejouée(s), 3 sautée(s), 0 en échec — les 15
          étapes nommées (dont check-baseline-arbitrage, check-gate-touche, check-push-sans-pr)
          toutes rc=0 ; confirme la fermeture de WINDOWS.md #8"
        status: pass
    human_judgment: false
  - id: D6
    description: "Rejeu `tests` : les deux rouges déjà documentés (WINDOWS.md #6, #7) se
      reproduisent à l'identique, aucun rouge nouveau"
    verification:
      - kind: integration
        ref: "replay-ci-jobs.sh --job tests : bilan 84 suites, 2 échecs, découverte indépendante
          =84 — mêmes deux fichiers que #6/#7 (test-register-codex-agent-path-traversal.sh T4,
          test-check-description-fidelity.sh PyYAML absent), déjà status=open"
        status: fail
    human_judgment: true
    rationale: "Rouges déjà remontés human_needed par le plan 41-01 (WINDOWS.md #6, #7), hors
      périmètre de ce plan (docs/ADR.md, CLAUDE.md), non neutralisés, non déclarés verts."
  - id: D7
    description: "Messages de commit du plan citent l'arbitrage attendu avec canal et date"
    verification:
      - kind: other
        ref: "Task 2, dernier bloc <automated> : commits_de_plan=12, sans_canal=0"
        status: pass
    human_judgment: false

# Metrics
duration: ~30min
completed: 2026-09-23
status: complete
---

# Phase 41 Plan 03: Doctrine du volet admin — ADR-072 amendée, ADR-059 amendée, CLAUDE.md corrigé Summary

**ADR-072 et ADR-059 amendées (contournement nommé D-02bis, politique hotfix, retour arrière),
`CLAUDE.md` reçoit une section « Protection côté serveur » et corrige l'ouverture désormais fausse
de « Gardes in-repo » — sans réécrire une seule ligne de texte antérieur.**

## Performance

- **Duration:** ~30 min
- **Completed:** 2026-09-23
- **Tasks:** 2/2
- **Files modified:** 2 (`docs/ADR.md`, `CLAUDE.md`)

## Accomplishments

- **ADR-072 amendée** : sous-section `### Amendement du 2026-09-23 — posture côté serveur (volet
  admin)` ajoutée en fin de la section ADR-072 (juste avant `## ADR-073 :`), ouverte par la note
  `> **ADR-072 : amendement du 2026-09-23 (Phase 41, volet admin)** — …`. Contenu : décision
  (rulesets D-M1, sources versionnées, CODEOWNERS, règles de `main` D-03/D-04/D-05/D-10) ;
  contournement nommé D-02bis (tableau à quatre colonnes, deux `User` `always` —
  `samuel-neveugall` 151974738 et `picmakpro` 203482067 —, jamais `exempt`) écrit sans adoucir :
  suppression et force push de `main` refusés hors liste, **acceptés et tracés** pour Samuel et
  Willy (« Bypassed rule violations », rule suite `bypass`, alarme G-3) ; `check-release-tag` non
  requis (demande WhatsApp de Samuel, 2026-09-23) ; politique hotfix ; PR en vol (#87, #88) ;
  retour arrière écrit avant la pose (`enforcement=disabled`) ; conséquences pour O-3 (« gardée par
  défaut + tracée », jamais fermée) ; inconnus mesurés à la pose M-1 à M-4 ; QUAL-01 (aucun gate
  créé). Statut d'index amendé, texte antérieur octet-identique.
- **ADR-059 amendée** : note datée en fin de section (avant `## ADR-060 :`) — sur ce dépôt,
  « Branche pour tout travail de phase » (écartée le 2026-07-28) devient la règle par défaut,
  conséquence de D-03 et D-02bis ; tableau d'options et texte d'origine intacts. Statut d'index
  amendé.
- **`CLAUDE.md`** : section `## Protection côté serveur — main et tags v*` insérée juste avant
  `## Gardes in-repo` (source versionnée `.github/rulesets/`/`CODEOWNERS`, PR obligatoire, checks
  requis, garde-fou par défaut + trace pour Samuel et Willy, tags `v*`). Ouverture de « Gardes
  in-repo » — devenue fausse le 2026-09-23 puisqu'elle affirmait l'absence de toute règle serveur
  et de tout accès admin — remplacée par une phrase qui renvoie à la nouvelle section. « Discipline
  de release » (zone touchée en parallèle par la PR #87, encore ouverte) et « Limite de fond »
  laissées octet-identiques.
- Aucune proposition des deux fichiers n'associe O-3 à un mot d'achèvement, même nié.
- Rejeu `gates` intégralement vert (14 rejouée(s), 0 en échec) — confirme que le correctif du
  frontmatter de `STATE.md` (commit d'orchestrateur `8d1ae26`, antérieur à ce plan) a bien fermé
  WINDOWS.md #8. Rejeu `tests` : mêmes deux rouges déjà ouverts (#6, #7), aucun rouge nouveau.
- Finding remonté, non corrigé dans ce diff (hors périmètre déclaré `docs/ADR.md`/`CLAUDE.md`) :
  **ADR-071 n'a aucune ligne d'index** (`grep -c '^| ADR-071 |' docs/ADR.md` = 0) — item BACKLOG
  « DIFFÉRÉ », déclencheur « prochain passage sur `docs/ADR.md` » — atteint par ce plan mais non
  traité, comme prévu par le plan.

## Task Commits

Each task was committed atomically:

1. **Task 1: amendement d'ADR-072 (D-02bis, hotfix, retour arrière) + statut d'index** -
   `1a62c29` (docs)
2. **Task 2: amendement d'ADR-059 + protection côté serveur dans CLAUDE.md** - `4f3857b` (docs)

**Plan metadata:** commit à suivre (SUMMARY + STATE + ROADMAP)

## Files Created/Modified
- `docs/ADR.md` - ADR-072 amendée (sous-section + statut d'index), ADR-059 amendée (note + statut
  d'index)
- `CLAUDE.md` - section « Protection côté serveur — main et tags v* », ouverture de « Gardes
  in-repo » corrigée

## Decisions Made
- L'amendement d'ADR-072 est placé en fin de SECTION ADR-072 (avant `## ADR-073 :`), pas en fin de
  fichier — la PR #89 (ADR-073) a été mergée avant l'exécution de ce plan, invalidant l'hypothèse
  d'écriture du plan. C'est le seul placement qui respecte à la fois le must_have (« en fin
  d'ADR-072 ») et la consigne de contexte (« ne jamais recréer ni contredire ADR-073 »).
- PROT-02 et PROT-03 restent cochés tels quels (clôture du 2026-09-18) : ce plan enrichit leur
  doctrine côté admin, il ne rouvre ni ne referme leurs checkboxes.

## Deviations from Plan

### Auto-fixed Issues

Aucune — les deux rouges de tests rencontrés (WINDOWS.md #6, #7) sont hors périmètre et déjà
documentés ; aucun bug introduit par ce plan.

### Dérive d'environnement documentée (pas un auto-fix — Rule 3 non applicable, script de
### vérification hors périmètre du plan)

**1. Bloc `<automated>` n°1 de la Task 1 — sous-contrôles `derniere_adr`/`historique_intact`.**
Le plan a été écrit quand ADR-072 était la dernière section de `docs/ADR.md`. Entre l'écriture du
plan et son exécution, la PR #89 (« ADR-073 : une release publie une évolution fonctionnelle… »,
arbitrage Samuel, AskUserQuestion session principale, 2026-09-23) a été mergée sur `main`, et cette
branche a été rebasée dessus (fait explicitement signalé dans les `context_facts` du dispatch) —
`docs/ADR.md` a désormais `## ADR-073 :` juste après `## ADR-072 :`. Deux sous-contrôles du bloc
littéral du plan supposent structurellement qu'ADR-072 reste la dernière section :
- `derniere_adr=$last` compare le dernier titre `## ADR-NNN :` du fichier à `ADR-072` — il vaut
  désormais `ADR-073` (fichier inchangé sur ce point, aucune section n'a été ajoutée ou retirée
  ailleurs qu'à l'endroit prévu).
- `historique_intact=$hist` compare, sans borne de fin, le texte d'ADR-072 à EOF côté merge-base et
  côté fichier courant — côté merge-base cette plage inclut désormais tout ADR-073 (absent côté
  fichier courant, dont la capture s'arrête à ma nouvelle sous-section, placée avant `## ADR-073`).
  Les deux plages ne peuvent structurellement plus être égales, quel que soit le contenu que
  j'écris.

Ces deux échecs sont **mécaniques**, causés par un changement d'environnement antérieur à
l'exécution (rebase sur la PR #89), pas par une erreur de contenu — les 39 termes requis, l'unicité
de l'amendement, et l'intégrité du texte antérieur (vérification corrigée, bornée à `## ADR-073`
au lieu d'EOF) sont tous prouvés verts. Correctif du script de vérification embarqué dans
`41-03-PLAN.md` non appliqué : il est hors du périmètre `files_modified` déclaré de ce plan
(`docs/ADR.md`, `CLAUDE.md`) et modifier une assertion de vérification sans validation humaine
constituerait un contournement de gate (ADR-031, cf. le précédent du plan 41-02 sur
`check-dev-bootstrap.sh`). Consigné ici, jamais neutralisé.

**2. Ledger `WINDOWS.md` : append best-effort bloqué par une désynchro préexistante.** La tentative
d'enregistrer la dérive ci-dessus via `gsd-tools windows append` a échoué :
`Ledger counts disagree with entries: frontmatter open/waived/fixed/total=3/1/4/8 but entries yield
2/1/5/8`. Cause : l'entrée #8 a été marquée `fixed` par l'orchestrateur (commit `8d1ae26`) sans
passer par `gsd-tools windows fixed`, laissant les compteurs du frontmatter désynchronisés des
entrées réelles. Hors du périmètre déclaré de ce plan (`.planning/WINDOWS.md` n'y figure pas) ;
non corrigé ici. Per l'instruction d'exécution : la population du ledger est best-effort, ce blocage
ne bloque pas l'exécution du plan.

---

**Total deviations:** 0 auto-fixé ; 1 dérive d'environnement documentée (mécanique, pré-existante à
l'exécution, sans impact sur le contenu livré) ; 1 tentative de population du ledger bloquée par
une désynchro préexistante des compteurs.
**Impact on plan:** Aucun sur le livrable — les deux tâches déclarées sont exécutées et vérifiées
(hors des deux sous-contrôles mécaniquement invalidés par l'environnement) ; les deux rouges `tests`
préexistants restent documentés, pas neutralisés.

## Issues Encountered
- Voir « Dérive d'environnement documentée » ci-dessus (bloc 1 de la Task 1) et « Ledger WINDOWS.md »
  (append best-effort bloqué, désynchro préexistante des compteurs, hors périmètre).
- ADR-071 sans ligne d'index dans `docs/ADR.md` : constaté, remonté, pas corrigé dans ce diff
  (item BACKLOG « DIFFÉRÉ », déclencheur « prochain passage sur `docs/ADR.md` » atteint par ce
  plan mais hors de son périmètre déclaré).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- La doctrine du volet admin (ADR-072, ADR-059, `CLAUDE.md`) est écrite et mergeable avant toute
  pose de ruleset (plan 41-05), retour arrière compris.
- Le finding ADR-071 (index manquant) et la désynchro des compteurs de `WINDOWS.md` restent ouverts,
  à trancher par un humain — ni l'un ni l'autre ne bloque la suite de la phase.
- PROT-01 reste non coché (cochage réservé au plan 41-13, sur pièce).

---
*Phase: VFDO-41-posture-de-protection-du-d-p-t*
*Completed: 2026-09-23*

## Self-Check: PASSED
- `docs/ADR.md` (ADR-072 amendée, ADR-059 amendée) : FOUND
- `CLAUDE.md` (section serveur + ouverture corrigée) : FOUND
- Commits `1a62c29`, `4f3857b` : FOUND dans `git log`
