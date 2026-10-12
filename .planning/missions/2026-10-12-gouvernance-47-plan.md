# Mission 2026-10-12 — Phase 47 (gouvernance) : cadrage et planification

**Manager :** `vf-dev-manager-p47-cadrage`
**Verrou :** génération `DRIVER.lock.gen.1791803679.64728` (verrou du worktree), aucun orphelin à
l'acquisition ni à la clôture.
**Branche :** `gouvernance/phase-47-cadrage`, partie de `origin/gouvernance/phase-46-execution`
(`78808126`, PR #136, non mergée). Worktree isolé `agent-a27d54e8a8701d01e`.
**Compartiment :** `gouvernance` (`--ws gouvernance` à chaque appel GSD).
**Feu vert :** Willy, message en session principale, 2026-10-12 (« oui » : cadrer la 47 en
parallèle de la 46.1, exécution de la 47 APRÈS la 46.1).
**Périmètre :** cadrage et planification de la Phase 47. Aucune exécution, aucun rejeu, aucun
armement, aucun merge, aucune release.
**Issue :** `human_needed` — planification commitée, plan-check **non PASSED** : Q8 et Q9 attendent
Willy (inscrites dans `47-DISCUSSION-LOG.md`).

## Plan de bataille (DAG `2026-10-12-gouvernance-47-plan.dag.json`)

`recherche-47` ∥ `scouting-47` → `cadrage-47` → `plan-47` → `plancheck-47` → `suivi-47` → `pr-47`

`plan-47` a été rouvert par `dag.sh reopen` après le tour 1 ; les révisions 2 à 6 sont des mandats
ciblés sur le même nœud. Le DAG est gelé sur `plancheck-47` (Q9).

## Déroulé

1. **Installation.** Branche créée depuis `origin/gouvernance/phase-46-execution`. Le premier push a
   été refusé (403) : le compte `gh` actif était `Avma-ai` (basculé le 2026-10-07 18:26), `picmakpro`
   connecté mais inactif. Option C de la session principale (local d'abord, aucun changement de compte
   ni jeton), puis bascule `gh auth switch -u picmakpro` faite par le head à la demande de Willy
   (message en session principale, 2026-10-12) ; push normal ensuite. `.claude/hooks` et
   `.claude/scripts` existaient déjà comme dossiers copiés à la création du worktree : liens non posés.
2. **Relevés (ADR-045)**, en parallèle, lecture seule : `47-RECHERCHE-BAUX.md` (Claude Code 2.1.296)
   et `47-SCOUTING.md`. Commit `cd82e915`. Faits structurants : le hook ne lit jamais `session_id` ;
   `agent_id` présent en `PreToolUse` de sous-agent (≥ 2.1.69) ; jeton présenté par l'agent =
   forgeable ; `flock(1)` absent de macOS ; G2′ sans code ; `TaskCompleted` toujours absent par
   défaut ; `onFailure: "block"` depuis 2.1.295. Point d'entrée revu : la prémisse « même
   `TaskCompleted` que G3/G4 » est périmée (P46-D-01).
3. **Cadrage** (geste du manager). Sept questions relayées par `SendMessage(main)` (commit
   `bcc78cbf`), réponses verbatim de Willy : (a) partout. `47-CONTEXT.md` (P47-D-01..17), BAIL-01..10
   au ledger du compartiment. Commit `a5107583`.
4. **Planification** par `vf-coder` (`gsd-plan-phase 47 --ws gouvernance`) : RESEARCH (P47-D-04a,
   01a, 02a résolus), PATTERNS, VALIDATION, 12 plans ; plan-checker interne PASSED au 2ᵉ tour.
   Commits `2134f0ca`, `34e9062d`, `25bef11d`, `1c92cd1d`.
5. **Plan-check frais** : six tours, voir la table. Révisions ciblées `9873c0a0` (17 corrections,
   scission de 47-07, 14 plans en 10 vagues), `03ba6a7e`, `900775dd`, `be1e039f`, `20e8d3cb`,
   `18866624`.
6. **Suivi.** ROADMAP §47 posée à la main (`51de3819` : Depends on corrigé, note P46-D-19 complétée,
   `BACKLOG.md:74 → :169`, liste des 14 plans). STATE : une ligne de position ajoutée (`31857ecf`),
   **compteurs du frontmatter non touchés** (zone partagée avec la branche 46.1 ; `total_plans` à
   recompter au merge, +14).

## Plan-check frais

| Tour | Juge | Résultat |
|---|---|---|
| 1 | deux checkers (objectif ; exécutabilité) | 1 bloquant (miroir de G2′ et clôture par `Bash`) + 15 avertissements |
| 2 | un checker, angles combinés | 0 bloquant, 3 avertissements |
| 3 | idem | 0 bloquant, 1 avertissement |
| 4 | idem | 0 bloquant, 1 avertissement |
| 5 | idem, énumération générative | 1 bloquant (exemption sur présence de `CLOTURE.md`) |
| 6 | idem | 3 bloquants (test génératif non exécutable tel qu'écrit, `imputer` sans période, fenêtre avant le registre) |

**Diagnostic.** Les tours 2 à 6 ont tous porté sur le même objet : la règle miroir de G2′ au recalcul
pour une clôture faite hors outil (P47-D-04). Chaque correction a ajouté un mécanisme ; le tour suivant
y a trouvé une brèche. Cause : G3 est une fonction pure du disque, G2′ dépend d'un historique que
`Bash` contourne ou réécrit (P45-D-10). Le manager a arrêté d'itérer et a remonté la portée à Willy
(Q9). Le bloquant `imputer` sans période, indépendant de Q9, est corrigé (`18866624`) ; 47-09 n'est
plus touché en attendant la réponse.

## Arbitrages humains

Canal : Willy, AskUserQuestion session principale, 2026-10-12, relayé verbatim par la session
principale. Q1 à Q7 : recommandation (a) suivie → P47-D-01..07.

**En attente** (inscrites dans `47-DISCUSSION-LOG.md`, commit `21098c3a`) :
- **Q8** — armement de `BAIL`/`G2P` avant une liste réelle (condition `LISTE-REELLE n ≥ 1` ajoutée par
  le planificateur) ; recommandation (a) : condition gardée.
- **Q9** — portée du miroir de G2′ ; recommandation (a) : détection au mieux, garantie bornée aux
  clôtures par outil, « clôture hors outil » en limite nommée.

## Décisions du manager (renversables par Willy)

P47-D-08 à P47-D-17 (annoncées, non renversées). Décisions de plan signalées : clé = sha256 de la
forme NFC du chemin ; `meta` en `clé=valeur` terminé par `fin=1`, publié par `os.link` ; geste de prise
= demande écrite par outil sous `.planning/baux/demandes/` (jamais nettoyées, limite nommée) ;
`.planning/baux/.gitignore` posé à la première prise ; écrivain hors outil qui dérive = `contournement`
tracé, pas de refus ; scission 7a/7b dès la livraison ; premier remplissage de la liste = geste humain
ou dérogation G6 ; empreinte du triplet de clôture sans inode (option A) ; 47-01 et 47-05 non scindés
(« scinder si l'exécution dérive ») ; `conductor` bumpé en patch provisoire, renuméroté au rebase.

## Limites et constats de mission

- **Budget de méthode** : snapshot de début **non posé** — `vf-mission-budget.snap` vit sous le `.git`
  commun et y portait déjà celui d'une autre mission (génération `…1791803429…`, 2026-10-12 11:10Z) ;
  l'outil n'isole pas par mission, le poser l'aurait écrasé. E7 est donc INDÉTERMINÉ pour cette mission.
  À la clôture, `check-method-budget.sh --auto --dry-run` : STATE gouvernance à 30 Ko (budget 8 Ko),
  ROADMAP fiabilite à 144 Ko, BACKLOG à 36 sujets — préexistants, **non archivés** (le brief interdit
  de réécrire STATE/ROADMAP au-delà du §47 et de la ligne de position).
- `check-dev-bootstrap.sh` non rejoué : la garde d'isolation du worktree refuse `bash <script>`.
- Zone partagée avec la 46.1 : `46.1-CONTEXT.md` lu sur le commit local `8519c402` (non poussé au moment
  du cadrage) ; les plans se re-valident contre la 46.1 livrée avant toute exécution (P47-D-10).
- Conflits de merge attendus avec la branche 46.1 : `REQUIREMENTS.md` (lignes de traçabilité ajoutées
  au même endroit), ligne de position de `STATE.md`. Triviaux.
- Version `planning-core` v2.12.0 « à confirmer au moment d'exécuter ».

## Témoins

- **Invariants :** `check-mission-invariants.sh` → 3 (SAIN).
- **Drapeaux d'enchaînement :** `_auto_chain_active` et `auto_advance` valent `false` (lu dans
  `.planning/config.json`).
- **`check-state-integrity.sh --file .planning/workstreams/gouvernance/STATE.md`** : ✓ conforme.
- **`check-machine-paths.sh`** : ✓, 1982 fichiers.
- **Frontmatter du STATE** : fermé à la ligne 26.
- **Orphelins du registre d'agents** : 0.

## Coût (subagent_tokens relevés sur les notifications)

| Agent | Nœud | Jetons |
|---|---|---|
| general-purpose, recherche doc | recherche-47 | 199 457 |
| general-purpose, état des lieux | scouting-47 | 294 190 |
| vf-coder, `gsd-plan-phase` | plan-47 | 193 856 |
| gsd-plan-checker A, tour 1 | plancheck-47 | 135 253 |
| gsd-plan-checker B, tour 1 | plancheck-47 | 213 393 |
| vf-coder, révision 1 | plan-47 | 588 223 |
| gsd-plan-checker, tour 2 | plancheck-47 | 116 494 |
| vf-coder, révision 2 | plan-47 | 163 841 |
| gsd-plan-checker, tour 3 | plancheck-47 | 116 430 |
| vf-coder, révision 3 | plan-47 | 132 196 |
| gsd-plan-checker, tour 4 | plancheck-47 | 95 805 |
| vf-coder, révision 4 | plan-47 | 137 274 |
| gsd-plan-checker, tour 5 | plancheck-47 | 127 965 |
| vf-coder, révision 5 | plan-47 | 258 955 |
| gsd-plan-checker, tour 6 | plancheck-47 | 146 294 |
| vf-coder, révision 6 | plan-47 | 105 939 |
| **Total** | | **3 025 565** |

- **Mandats émis par le manager :** 16 — 2 general-purpose, 7 vf-coder, 7 gsd-plan-checker. Les agents
  lancés par le workflow de `gsd-plan-phase` ne sont pas comptés ici.
- **Juges de plan frais :** 7 passes pour 6 tours.

## Preuves E6

Aucune exécution dans cette mission : aucun bloc `preuves` de `vf-coder` à relayer (les mandats étaient
des mandats de planification ; `estimate`/`actuals` absents, aucun PLAN exécuté).

## Next step

Faire trancher Q9 (puis Q8) par Willy ; sur la réponse, relancer une mission courte : révision de
47-09 (et 47-11) selon Q9, un plan-check frais jusqu'à PASSED, mise à jour de la PR. L'exécution de la
47 reste conditionnée à la livraison de la 46.1.
