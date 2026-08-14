---
phase: VFDO-28-preuve-que-ce-qui-est-arm-dans-le-plugin-est-arm-chez-l-util
plan: 02
subsystem: dev-orchestrator
tags: [awk, bash, gate, capability-activation, frontmatter, mcp, as-installed-testing]

requires:
  - phase: 28-01
    provides: "check-capability-activation.sh regle 4/4bis, liste close a une ligne (isolation), inject-mcp-tools.sh premier porteur reel de # vf-provides: mcp-servers"
provides:
  - "Liste close a DEUX lignes : isolation -> worktree-baseref, vf-mcp-consumer/vf-mcp-tools -> mcp-servers."
  - "5 artefacts distribues (vf-coder.md, vf-reviewer.md, vf-app-fixer.md, vf-test-orchestrator.md, vf-test-runner.md) declarent vf-requires: mcp-servers sous leur armement MCP existant."
  - "vf-requires admis dans les cles KNOWN de check-agents.sh (6 repertoires d'agents + AGENT.md passent --strict sans warning)."
  - "Cas d'opposabilite des porteurs # vf-provides: (table nommee comparee par comm au corpus reel, mutation sur copie, discriminance de inject-mcp-tools.sh prouvee par execution dans les trois sens rouge/vert/prive)."
  - "En-tete du gate portant les cinq bornes declarees de la regle 4 (Phase 28, plan 28-02) + corollaire A-9 sur isolation:."
affects: [VFDO-28-03, dev-orchestrator check-capability-activation.sh test suite]

actuals:
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Bornes d'en-tete numerotees, redigees par le gate lui-meme, assertees par -h via des chaines litterales (jamais un seuil de nombre de lignes — nombre magique fragile explicitement rejete par le plan)."
    - "Comparaison de porteurs par comm (jamais diff/index() nu) — patron deja pose en 28-01 reconduit pour l'opposabilite des porteurs."

key-files:
  created: []
  modified:
    - plugin/dev-orchestrator/scripts/check-capability-activation.sh
    - plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh
    - plugin/dev-orchestrator/agents/vf-coder.md
    - plugin/dev-orchestrator/agents/vf-reviewer.md
    - plugin/mobile-test-team/agents/vf-app-fixer.md
    - plugin/mobile-test-team/agents/vf-test-orchestrator.md
    - plugin/mobile-test-team/agents/vf-test-runner.md
    - plugin/conductor/scripts/check-agents.sh
    - .planning/phases/VFDO-28-preuve-que-ce-qui-est-arm-dans-le-plugin-est-arm-chez-l-util/28-RESEARCH.md

key-decisions:
  - "Regle 4 rend DEUX verdicts (VERT/ROUGE) et aucun troisieme etat par artefact — divergence assumee avec la recommandation « trois verdicts » de 28-RESEARCH.md Open Question 2, motif ecrit dans l'en-tete (borne 5) : la jointure est statique (A-4 i), le gate ne peut pas observer une degradation gracieuse au moment de l'usage."
  - "isolation: RESTE dans la liste close malgre la degradation gracieuse de gsd-core 1.10.0 (worktree.baseRef ne casse plus en silence) : poser baseRef: \"head\" tait la verification sans resoudre la base, et le second verrou open-gsd/gsd-core#3302 (retour des commits d'un worker isole) reste intact. Motif reecrit en corollaire A-9, jamais retire."
  - "L'en-tete ne porte aucun seuil de nombre de lignes (le plan l'interdit explicitement) — l'acceptance criterion sur -h asserte cinq chaines litterales, pas un volume."

requirements-completed: [ARMD-01, ARMD-02, ARMD-05, ARMD-09, ARMD-10]

coverage:
  - id: D7
    description: "Les 5 artefacts distribues portant vf-mcp-consumer: ou vf-mcp-tools: declarent vf-requires: mcp-servers et le gate les rend VERTS ; retirer la declaration de l'un d'eux le fait rougir en le nommant."
    requirement: "ARMD-05"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh#R10-R15"
        status: pass
    human_judgment: false
  - id: D8
    description: "Le gate ne rougit pas sur la phrase de prose contenant le token MCP en vf-reviewer.md:45 : il ne lit que les cles du frontmatter."
    requirement: "ARMD-09"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh (piege anti-prose vf-reviewer.md:45)"
        status: pass
    human_judgment: false
  - id: D9
    description: "Tout script distribue portant # vf-provides: a, dans la suite, un cas prouvant qu'il rend non-zero quand sa precondition manque ; un porteur absent de la table du test fait echouer le test."
    requirement: "ARMD-10"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh (opposabilite des porteurs, comparaison par comm)"
        status: pass
    human_judgment: false
  - id: D10
    description: "L'en-tete du gate declare ce que la liste close couvre et ne couvre pas, la hierarchie avec check-agents.sh, le sort des SKILL.md, et la limite couverture declaree vs couverture effective."
    requirement: "ARMD-02"
    verification:
      - kind: unit
        ref: "bash plugin/dev-orchestrator/scripts/check-capability-activation.sh -h (cinq chaines litterales : as-installed testing, check-agents.sh, SKILL.md, couverture declaree, worktree.baseRef)"
        status: pass
    human_judgment: false
  - id: D11
    description: "vf-requires est admis dans les cles KNOWN de check-agents.sh, et les 6 repertoires d'agents passent --strict sans warning de champ inconnu."
    requirement: "ARMD-01"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/check-agents.sh execution reelle (6 repertoires d'agents + AGENT.md)"
        status: pass
    human_judgment: false

duration: reprise de session (tache 3 + clôture)
completed: 2026-08-14
status: complete
---

# Phase 28 Plan 02: Seconde ligne de la liste close (MCP), opposabilite des porteurs de preuve, bornes du gate

**`check-capability-activation.sh` gagne une seconde ligne d'armement surveille (`vf-mcp-consumer`/`vf-mcp-tools` → `mcp-servers`), 5 artefacts distribues declarent reellement leur precondition, la moitie « preuve » de la regle 4 (opposabilite des porteurs `# vf-provides:`) est etablie par execution dans la suite, et le gate ecrit ses propres bornes en en-tete pour ne jamais laisser croire qu'il couvre plus que son perimetre reel.**

## Performance

- **Tasks:** 3
- **Files modified:** 9 (8 dans le perimetre `<files>` du plan + `28-RESEARCH.md` au titre de la deviation encadree)
- Session reprise : taches 1 et 2 committees en amont (`355e5a6`, `42f215d`), tache 3 ecrite mais non committee au moment de la reprise ; ce mandat a verifie, complete et cloture.

## Accomplishments

- **Tache 1** — `ARM["vf-mcp-consumer"]` et `ARM["vf-mcp-tools"]` exigent la precondition `mcp-servers` (deja legale dans `OKID` depuis 28-01). 5 artefacts distribues (`vf-coder.md`, `vf-reviewer.md`, `vf-app-fixer.md`, `vf-test-orchestrator.md`, `vf-test-runner.md`) recoivent `vf-requires: mcp-servers` sous leur armement MCP existant. `vf-requires` admis dans les cles `KNOWN` de `check-agents.sh` (echappement Python preserve, verifie par execution reelle sur 6 repertoires d'agents + `AGENT.md`).
- **Tache 2** — Table nommee (`mcp-servers -> inject-mcp-tools.sh`) comparee par `comm` au corpus reel des scripts portant `# vf-provides:` en tete (porteur non tabule, entree perimee, ensemble vide : trois KO distincts). Mutation sur COPIE (jamais l'arbre reel) prouvant qu'un porteur non inscrit fait echouer la comparaison. Discriminance de `inject-mcp-tools.sh` prouvee par execution reelle dans les trois sens (rouge = precondition manquante -> code 1, vert = injectee puis relue -> code 0, environnement totalement prive de source -> code 3, jamais confondu avec le rouge).
- **Tache 3** — Cinq bornes ecrites dans l'en-tete du gate (Phase 28, plan 28-02) : (1) ce que la liste close couvre/ne couvre pas — enumeree a la main, jamais deduite ; (2) la hierarchie avec `check-agents.sh` (palier dur vs palier de relation) et pourquoi les deux gardes subsistent ; (3) l'asymetrie agent/skill — la regle 4 est le seul controle machine sur une cle de frontmatter `SKILL.md` ; (4) le patron *as-installed testing* (autopkgtest Debian) avec sa limite honnete (couverture declaree ≠ couverture effective) ; (5) l'arbitrage « deux verdicts, pas trois » avec son motif (jointure statique, A-4 i), plus le corollaire A-9 : `isolation:` reste dans la liste close, motif reecrit pour la degradation gracieuse de gsd-core 1.10.0.
- Une glitch de mise en forme dans la borne 4 (ligne de 33 caracteres coupant la phrase avant son rewrap normal, ~95-100 caracteres comme le reste du fichier) a ete corrigee lors de la reprise — reformattage pur, aucun mot ajoute/retire/modifie.

## Task Commits

1. **Tache 1: seconde ligne de la liste close (armements MCP) et 5 declarations reelles** - `355e5a6` (feat)
2. **Tache 2: opposabilite des porteurs `# vf-provides:`, prouvee par execution** - `42f215d` (test)
3. **Tache 3: la regle 4 ecrit ses cinq bornes declarees** - `df875ab` (docs)

## Files Created/Modified

- `plugin/dev-orchestrator/scripts/check-capability-activation.sh` — seconde ligne `ARM`, en-tete des cinq bornes + corollaire A-9.
- `plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh` — cas R10-R15 (grammaires MCP, piege anti-prose, frontiere 4bis, mutation sur copies) + cas d'opposabilite des porteurs.
- `plugin/dev-orchestrator/agents/vf-coder.md`, `plugin/dev-orchestrator/agents/vf-reviewer.md`, `plugin/mobile-test-team/agents/vf-app-fixer.md`, `plugin/mobile-test-team/agents/vf-test-orchestrator.md`, `plugin/mobile-test-team/agents/vf-test-runner.md` — `vf-requires: mcp-servers` ajoute.
- `plugin/conductor/scripts/check-agents.sh` — `vf-requires` admis dans `KNOWN`.
- `.planning/phases/VFDO-28-preuve-que-ce-qui-est-arm-dans-le-plugin-est-arm-chez-l-util/28-RESEARCH.md` — deviation encadree (voir ci-dessous).

## Decisions Made

- Regle 4 : deux verdicts (VERT/ROUGE), aucun troisieme etat par artefact — le troisieme etat de la doctrine du gate reste porte par les planchers (exit 2, NON VERIFIABLE), jamais par un « artefact a moitie arme ». Divergence assumee avec la recommandation « trois verdicts » de `28-RESEARCH.md` Open Question 2 ; A-9 l'autorise a condition d'ecrire le motif — ecrit dans la borne 5.
- `isolation:` reste dans la liste close malgre la degradation gracieuse de gsd-core 1.10.0 : `baseRef: "head"` tait la verification sans resoudre la base, et le second verrou `open-gsd/gsd-core#3302` (retour des commits d'un worker isole) reste intact. Un armement dont le reglage « sur » eteint le controle n'est pas un armement sur.
- Aucun seuil de nombre de lignes sur l'en-tete (le plan l'interdit explicitement comme nombre magique fragile) — l'acceptance criterion sur `-h` asserte cinq chaines litterales exactes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Cosmetic] Rewrap casse en milieu de phrase dans la borne 4**
- **Found during:** reprise de session, controle de la fin du bloc de bornes signale par le mandat comme point de doute.
- **Issue:** une ligne de commentaire de 33 caracteres (`#   qu'un `# vf-provides:` existe`) rompait le rewrap normal (~95-100 caracteres, patron pratique par le reste du fichier) avant de reprendre sur la ligne suivante — lisible mais visuellement incoherent avec le patron redactionnel.
- **Fix:** reformattage des lignes 111-117 en blocs de largeur homogene, AUCUN mot ajoute, retire ou reformule.
- **Files modified:** `plugin/dev-orchestrator/scripts/check-capability-activation.sh`
- **Verification:** diff confirme (via `awk`) qu'aucune ligne non-commentaire n'est touchee par la tache 3 dans son ensemble ; `-h` toujours 0 avec les cinq chaines requises.
- **Committed in:** `df875ab` (Tache 3, aucun commit separe — corrige avant le commit de la tache).

### Declared Deviations (hors `<files>` du plan, acceptance criterion oblige)

**2. [Deviation declaree] Chemin machine absolu dans `28-RESEARCH.md:858`**
- **Found during:** verification de l'acceptance criterion `bash scripts/check-machine-paths.sh` (sort 0) de la tache 3.
- **Issue:** `check-machine-paths.sh` sortait 1 sur `/Users/<user>/.local/bin/claude` (§9, ligne 858 de `28-RESEARCH.md`) — violation preexistante, introduite par le commit de cadrage `ad03fc6`, hors `<files>` du plan 28-02, deja signalee par les deux revues de 28-01 (voir `28-01-SUMMARY.md`, section Next Phase Readiness).
- **Fix:** correction minimale et portable (`/Users/<user>/.local/bin/claude` → `~/.local/bin/claude`), meme ligne, meme nombre de lignes du fichier (1329 avant/apres), aucune reformulation de la phrase.
- **Files modified:** `.planning/phases/VFDO-28-preuve-que-ce-qui-est-arm-dans-le-plugin-est-arm-chez-l-util/28-RESEARCH.md`
- **Verification:** `bash scripts/check-machine-paths.sh` → 0 (919 fichiers suivis, aucun chemin absolu de machine restant).
- **Committed in:** `34409cf`, commit separe et explicitement etiquete deviation.
- **Perimetre :** seule violation trouvee (le rapport `check-machine-paths.sh` n'en nommait qu'une) ; correction jugee trivialement sure (litteral remplace par sa forme portable standard, aucune ambiguite).

---

**Total deviations:** 1 auto-fixed (cosmetique, aucun mot change) + 1 deviation declaree (fichier hors `<files>`, corrigee pour satisfaire un acceptance criterion de la tache 3, consignee au protocole GSD).
**Impact on plan:** Aucune derive de perimetre au sens D-NN. Le fichier touche hors `<files>` (`28-RESEARCH.md`) l'est uniquement au titre de la deviation encadree explicitement anticipee par le mandat de reprise.

## Verification — acceptance criteria de la tache 3, un par un

1. `bash plugin/dev-orchestrator/scripts/check-capability-activation.sh -h` → exit **0**, contient les cinq chaines `as-installed testing`, `check-agents.sh`, `SKILL.md`, `couverture declaree`, `worktree.baseRef` (verifie par recherche litterale sur la sortie captee). Aucun seuil de lignes asserte.
2. `bash plugin/dev-orchestrator/scripts/check-capability-activation.sh` → exit **0** sur l'arbre reel : « conforme — univers balaye : 23 toggle(s)…, 10 brique(s) routee(s)…, 2 toggle(s) sous marqueur… ».
3. `bash plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh` → exit **0**, bilan « 58 cas — 58 OK / 0 KO » (identique au compte de reference d'avant la tache).
4. Ligne `isolation` toujours presente dans la table des armements (`ARM["isolation"] = "worktree-baseref"`, ligne 490), motif adjacent citant `open-gsd/gsd-core#3302`.
5. `bash scripts/check-machine-paths.sh` → exit **0** apres la deviation declaree ci-dessus (etait 1 avant, sur une violation hors perimetre du plan).

**Preuve « aucune ligne executable modifiee » :** `git diff` de la tache 3 filtre par `awk` (lignes ajoutees/retirees ne commencant ni par `#` ni vides) → aucune sortie. Le diff entier est constitue de commentaires shell (en-tete du script) et de commentaires awk (bloc `ARM`, prefixe `#` a l'interieur du programme awk).

## Issues Encountered

None au-dela des deviations ci-dessus.

## User Setup Required

None - aucune configuration de service externe requise.

## Next Phase Readiness

- Liste close a deux lignes, 5 declarations reelles, opposabilite des porteurs de preuve etablie par execution, en-tete du gate portant ses cinq bornes — la tranche tracante de la Phase 28 est complete pour ce plan.
- Pret pour 28-03 (as-installed testing sur un lab frais).
- Aucun blocage : arbre reel vert (`check-capability-activation.sh` → 0), suite du module 58/58, `check-machine-paths.sh` → 0, aucun sixieme gate introduit (D-03 respecte).

---
*Phase: VFDO-28-preuve-que-ce-qui-est-arm-dans-le-plugin-est-arm-chez-l-util*
*Plan: 02*
*Completed: 2026-08-14*
