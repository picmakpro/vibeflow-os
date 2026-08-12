---
phase: VFDO-28-preuve-que-ce-qui-est-arm-dans-le-plugin-est-arm-chez-l-util
plan: 01
subsystem: dev-orchestrator
tags: [awk, bash, gate, capability-activation, frontmatter, adr-054]

requires:
  - phase: 24-doc-ne-promet-pas-un-geste-inerte
    provides: check-capability-activation.sh (regles 1, 2, 2bis, 3 — patron reutilise a lidentique pour la regle 4)
provides:
  - "Regle 4 dans check-capability-activation.sh : un artefact qui arme isolation: (liste close) sans vf-requires: worktree-baseref legal, leve par un # vf-provides: worktree-baseref present dans le corpus de scripts balaye, sort en 1 (ECART regle 4, fichier:ligne)."
  - "Regle 4bis : un vf-requires: citant un id hors de la table des ids legaux sort en 1 (ECART regle 4bis) ; un vf-requires legal sans armement reste 0 (moitie declaree de D-01)."
  - "Quatre planchers anti-vert-a-vide (univers d'armement vide, corpus de preuve sans marqueur, table des armements vide, table des ids legaux vide) sortant tous en 2, jamais 0."
  - "inject-mcp-tools.sh, premier porteur reel de # vf-provides: mcp-servers."
  - "VF_CAPACT_ARMED / VF_CAPACT_PROVIDERS : deux canaux de testabilite (deux dispositions depot/lab, profondeur 1, jamais de lien symbolique)."
affects: [VFDO-28-02, VFDO-28-03, dev-orchestrator check-capability-activation.sh test suite]

actuals:
  tokens: 7776
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Troisieme discriminant FILENAME (FILENAME in ISARM / FILENAME in ISPRV) pour separer deux corpus neufs du bloc corpus generique sans condition, dans le meme awk unique passe en argv."
    - "Substitution shell `-` (et non `:-`) pour un canal de surcharge devant honorer une valeur explicitement vide, distinct de labsence totale de la variable."

key-files:
  created: []
  modified:
    - plugin/dev-orchestrator/scripts/check-capability-activation.sh
    - plugin/dev-orchestrator/scripts/inject-mcp-tools.sh
    - plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh

key-decisions:
  - "ARM/OKID (liste close des armements + table des ids legaux) sont des tables litterales dans le corps de lawk, jamais surchargeables par variable d'environnement — la doctrine ne se deplace pas par `export` (T-28-01-05)."
  - "Regle 4 et 4bis ajoutees au gate existant, aucun sixieme gate (D-03) et aucun fichier neuf (compteur « 52 suites » des deux README preserve)."
  - "`ARMED`/`PROVIDERS` passent de `${VAR:-defaut}` a `${VAR-defaut}` pour que VF_CAPACT_ARMED=\"\" en test produise un univers VRAIMENT vide (testabilite des planchers), sans regresser la production (variable totalement absente = cascade par defaut inchangee)."
  - "inject-mcp-tools.sh choisi comme premier porteur du marqueur car sa discriminance (--verify a trois exits) est deja implementee et deja couverte — aucune ligne de logique neuve, comportement inchange."

requirements-completed: [ARMD-01, ARMD-02, ARMD-03, ARMD-04, ARMD-06, ARMD-07]

coverage:
  - id: D1
    description: "Un artefact qui arme isolation: worktree sans precondition declaree (vf-requires: absent) fait sortir le gate en 1, message ECART regle 4 nommant l'artefact et fichier:ligne."
    requirement: "ARMD-03"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh#MUT-R2 regle 4(a)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Un vf-requires: legal leve par un # vf-provides: du meme id present dans le corpus de scripts balaye fait sortir le gate en 0, sans qu'aucun script ne soit execute."
    requirement: "ARMD-04"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh#R1 regle 4 conforme"
        status: pass
    human_judgment: false
  - id: D3
    description: "Le desarmement (isolation: et vf-requires: retires) fait verdir le gate — le cas #38 rejoue, discriminance bidirectionnelle."
    requirement: "ARMD-07"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh#MUT-R4 desarmement"
        status: pass
    human_judgment: false
  - id: D4
    description: "Univers d'artefacts vide, corpus de preuve sans marqueur, table d'armements vide ou table d'ids legaux vide font sortir le gate en 2, jamais 0."
    requirement: "ARMD-06"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh#R5 plancher / R6 plancher"
        status: pass
    human_judgment: false
  - id: D5
    description: "Regle 4bis : id hors table sort en 1 ; vf-requires legal sans armement reste 0 (moitie declaree de D-01, jamais un ecart)."
    requirement: "ARMD-01"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh#R7 regle 4bis / R8 contre-epreuve D-01"
        status: pass
    human_judgment: false
  - id: D6
    description: "Aucun artefact distribue ne porte l'armement isolation: — l'etat mesure (0 porteur sur 51 artefacts du corpus d'armement) doit le rester."
    verification:
      - kind: other
        ref: "for f in plugin/*/agents/*.md plugin/*/AGENT.md plugin/*/SKILL.md plugin/*/skills/*/SKILL.md; do awk '/^isolation:/{n++} END{exit (n>0)}' \"$f\" || exit 1; done"
        status: pass
    human_judgment: false

duration: ~40min
completed: 2026-08-12
status: complete
---

# Phase 28 Plan 01: Regle 4 du gate d'activation — armement `isolation:` sans precondition distribuee

**`check-capability-activation.sh` gagne une regle 4 (et 4bis) qui rougit quand un artefact distribue arme `isolation: worktree` sans que la precondition `worktree-baseref` soit levee par un `# vf-provides:` reel du corpus de scripts, et verdit au desarmement — le cas #38 rejoue de bout en bout sur fixtures synthetiques.**

## Performance

- **Duration:** ~40 min (execution inline, sans decoupage subagent — pas de wall-clock separe par tache)
- **Tasks:** 2
- **Files modified:** 3 (`check-capability-activation.sh`, `inject-mcp-tools.sh`, `test-check-capability-activation.sh`)

## Accomplishments
- Regle 4 posee dans le `END` de l'awk unique : trois sous-cas ROUGE (armement sans `vf-requires`, `vf-requires` ne citant pas l'id exige, id legal mais aucun `# vf-provides:` levant) sur les trois discriminants `FILENAME in ISARM` / `FILENAME in ISPRV` inseres avant le bloc corpus generique.
- Deux corpus neufs (`VF_CAPACT_ARMED`, `VF_CAPACT_PROVIDERS`), deux dispositions (depot de distribution / lab installe), profondeur 1, jamais de lien symbolique, bases `contracts.md`/`README.md`/`AGENTS.md` exclues.
- `inject-mcp-tools.sh` devient le premier porteur reel de `# vf-provides: mcp-servers`, sans aucun changement de comportement.
- Quatre planchers anti-vert-a-vide + regle 4bis (hygiene de declaration, id hors table) + lecture de la precondition non scindee (jq/config.json — arbitrage explicite en commentaire).
- Suite de tests : 12 cas neufs (regle 4 conforme, deux mutations rouges, une mutation de desarmement verte, deux planchers, regle 4bis, contre-epreuve D-01, non-regression du compteur de lignes de corpus), 1 cas existant (14) corrige pour porter un univers d'armement/de preuve minimal — 41/41 cas verts.

## Task Commits

1. **Tache 1: la regle 4 de bout en bout** - `be9e2eb` (feat)
2. **Tache 2: les planchers anti-vert-a-vide de la regle 4, et la regle 4bis** - `3b16343` (feat)

## Files Created/Modified
- `plugin/dev-orchestrator/scripts/check-capability-activation.sh` — regle 4, regle 4bis, quatre planchers, vocabulaire litteral (ARM/OKID), deux corpus neufs (ARMED/PROVIDERS), contrat des codes de sortie complete.
- `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` — en-tete augmentee du marqueur `# vf-provides: mcp-servers` (comportement inchange).
- `plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh` — fabriques `mk_agent_arme`/`mk_script_preuve`/`mk_script_decoy`/`mk_regle4_fixture`, helpers `run4`/`rc4_of`, 12 cas neufs, correctif du cas 14.

## Decisions Made
- Tables `ARM`/`OKID` litterales et non surchargeables (T-28-01-05) : la doctrine ne se deplace pas par `export`.
- `ARMED="${VF_CAPACT_ARMED-$ARMED_DEFAULT}"` (substitution `-`, pas `:-`) : une surcharge explicitement vide doit produire un univers VRAIMENT vide pour tester les planchers de la tache 2, sans changer le comportement de production (variable totalement absente = cascade inchangee). Deviation mineure decouverte pendant l'ecriture des tests de la tache 2 — voir ci-dessous.
- Mutation R3 (regle 4c) retire le fichier de preuve de la LISTE balayee (`VF_CAPACT_PROVIDERS`) plutot que du disque, avec un decoy portant un id different pour que le corpus de preuve ne tombe jamais a zero fichier (eviterait de prouver un plancher au lieu de la regle 4c visee).
- Cas 14 (lab installe) etendu d'un agent non arme et d'un script de preuve factice : sans univers d'armement/de preuve minimal, le nouveau plancher de la tache 2 le faisait rougir en 2 pour une raison etrangere au cas (fixture ne portant aucun fichier `.claude/agents/*.md`/`.claude/scripts/*.sh` avant ce correctif).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Apostrophes francaises dans le programme awk casse le programme bash englobant**
- **Found during:** Tache 1, premiere verification de syntaxe (`bash -n`)
- **Issue:** Le programme awk est un litteral entoure de guillemets simples en bash (`awk -F'|' '...'`). Les messages `ECART regle 4` que j'avais ecrits contenaient `l'artefact`, `l'id` — l'apostrophe fermait prematurement le guillemet bash englobant, provoquant `unexpected EOF` a l'execution.
- **Fix:** Reformulation sans apostrophe (`artefact`, `id exige`) dans les messages et les commentaires awk neufs, alignee sur le style deja pratique par le reste du fichier (`dun`, `letat`, `nest` — deviation orthographique volontaire deja presente dans le code existant, memoire projet `bash32-heredoc-substitution`).
- **Files modified:** `plugin/dev-orchestrator/scripts/check-capability-activation.sh`
- **Verification:** `bash -n` propre, suite verte.
- **Committed in:** `be9e2eb` (Tache 1, aucun commit separe — corrige avant le premier commit de la tache)

**2. [Rule 1 - Bug] bash 3.2 (macOS) leve `unbound variable` sur `"${ARR[@]}"` quand `ARR` est un tableau vide, sous `set -u`**
- **Found during:** Tache 1, execution de la suite existante (cas 14, lab installe — univers d'armement vide sur cette fixture)
- **Issue:** `set -uo pipefail` est deja en tete du script. `"${ARMED_FILES[@]}"`/`"${PROV_FILES[@]}"` peuvent etre des tableaux a zero element (aucun fichier arme/preuve trouve) ; bash 3.2 (celui du poste, memoire projet `bash32-multibyte-nom-de-variable`) traite cette expansion comme une variable non liee et fait echouer le script, la ou bash ≥4.4 l'aurait tolere.
- **Fix:** Idiome portable `"${ARR[@]+"${ARR[@]}"}"` partout ou ces tableaux (possiblement vides) sont expanses (construction `VF_CAPACT_ISARM`/`VF_CAPACT_ISPRV`, invocation finale de l'awk).
- **Files modified:** `plugin/dev-orchestrator/scripts/check-capability-activation.sh`
- **Verification:** cas 14 repasse au vert, 29/29 puis 36/36 cas verts.
- **Committed in:** `be9e2eb` (Tache 1, aucun commit separe — corrige avant le premier commit de la tache)

**3. [Rule 1 - Bug] Cas 14 (lab installe) perd son univers d'armement/de preuve par defaut apres la tache 2**
- **Found during:** Tache 2, apres la pose des quatre planchers anti-vert-a-vide
- **Issue:** La fixture du cas 14 ne cree aucun fichier `.claude/agents/*.md` ni `.claude/scripts/*.sh` reel (seulement des sous-dossiers `*-references/`) : son univers d'armement/de preuve par defaut tombe a zero, et le nouveau plancher (tache 2) le fait sortir en 2 au lieu du 0 attendu — pour une raison etrangere au sujet du cas (racine du lab, pas armement).
- **Fix:** Ajout d'un agent factice non arme (`dummy-agent.md`) et d'un script de preuve factice (`dummy-provider.sh`, id `mcp-servers`, jamais requis dans cette fixture) au lab de la fixture, pour reconstituer un univers minimal sans introduire d'ecart de regle 4.
- **Files modified:** `plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh`
- **Verification:** cas 14 redevient vert, 36/36 puis 41/41 cas verts.
- **Committed in:** `3b16343` (Tache 2, aucun commit separe — corrige avant le commit de la tache)

---

**Total deviations:** 3 auto-fixed (3 Rule 1 — bugs decouverts pendant l'ecriture, tous internes au perimetre de fichiers autorise, aucun n'a touche a une decision D-NN du cadrage).
**Impact on plan:** Aucun — les trois corrections sont des reparations d'implementation necessaires a la lettre du plan (portabilite bash 3.2, syntaxe awk, non-regression d'un cas de test existant). Aucune derive de perimetre, aucun fichier hors liste touche.

## Issues Encountered
None au-dela des deviations ci-dessus.

## User Setup Required
None - aucune configuration de service externe requise.

## Next Phase Readiness
- La tranche tracante de la Phase 28 est posee : `isolation:` est la seule ligne de la liste close, `worktree-baseref` et `mcp-servers` sont dans la table des ids legaux, `inject-mcp-tools.sh` est le premier porteur reel.
- Pret pour 28-02 (expansion de la liste close a `vf-mcp-consumer`/`vf-mcp-tools`, declarations sur l'existant, bornes du gate) et 28-03 (as-installed testing sur un lab frais).
- Aucun blocage : arbre reel vert (`bash plugin/dev-orchestrator/scripts/check-capability-activation.sh` → 0), suites voisines (`test-inject-mcp-tools.sh`, `test-dev-orchestrator.sh` 184/0) inchangees, compteur de suites toujours 52.
- Point d'attention hors perimetre de ce plan : `scripts/check-machine-paths.sh` rapporte 1 chemin absolu de machine dans `.planning/phases/VFDO-28-.../28-RESEARCH.md:858`, pre-existant (commit `ad03fc6`, hors du perimetre de fichiers de ce mandat) — a signaler au manager, pas corrige ici.

---
*Phase: VFDO-28-preuve-que-ce-qui-est-arm-dans-le-plugin-est-arm-chez-l-util*
*Plan: 01*
*Completed: 2026-08-12*
