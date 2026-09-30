## Traçabilité des arbitrages humains dans les messages de commit — ADOPTÉE 2026-09-10

**Statut : proposition soumise à validation humaine (ADR-031). Rien n'est appliqué.** Émise par
`vf-dev-manager` le 2026-09-10, en marge de la Phase 39.

**Le constat.** Le commit `8fc4b45` porte « (arbitrage Samuel) » dans son sujet. L'attribution était
**exacte** — vérifiée après coup : question posée par AskUserQuestion en session principale le
2026-09-09, trois options soumises, réponse (a). Mais elle n'était **pas vérifiable depuis le
commit** : le texte a exactement la même forme qu'il soit vrai ou fabriqué. C'est le lecteur
d'après qui paie — et ce lab a déjà connu un arbitrage fabriqué de cette façon (incident Phase 18).

**Le risque particulier** : quand le résultat coïncide avec ce que le relecteur recommandait
lui-même, la vérification d'origine est précisément ce qu'on omet.

**La forme proposée.** Un message de commit qui invoque un arbitrage humain nomme **le canal et la
date**, pas seulement la personne :

```
(arbitrage Samuel, AskUserQuestion session principale, 2026-09-09)
```

L'affirmation devient vérifiable au lieu d'être crue. Coût : quelques mots. Aucun outillage, aucun
gate — une convention de rédaction, applicable aux agents comme aux humains.

**TRANCHÉ le 2026-09-10** (arbitrage Samuel, AskUserQuestion session principale, 2026-09-10) :
**adoptée**, sans gate machine — la variante outillée est explicitement écartée, la forme écrite
suffit. Inscrite dans `plugin/dev-orchestrator/references/mission-contracts.md`.

**Reliquat, geste humain** : l'inscription d'une ligne dans le `CLAUDE.md` du dépôt (là où vivent les
conventions de commit) reste à faire **par Samuel**. Un agent ne modifie pas le `CLAUDE.md` d'un
dépôt sur instruction relayée par un autre agent — la décision est authentique, c'est le canal qui ne
convient pas pour ce fichier-là.

## Notifications de progression des agents managers — CLOS
**Capturé :** 2026-08-11 · **Clos :** 2026-08-17 (Phase 33 puis son **annexe D-33-H**) ·
**Origine de la résurgence :** le déclencheur inscrit ci-dessous — « demande récurrente de suivi de
mission longue distance » — s'est produit tel quel

Les missions pilotées par les managers (`vf-dev-manager`, `vf-design-manager`,
`vf-test-orchestrator`) sont longues et l'utilisateur n'est pas devant l'écran. Idée : **envoyer
une notification quand un agent manager termine sa mission** — et, en extension, **des
notifications aux passages d'étapes importantes** du plan de bataille (fin d'un nœud du DAG,
verdict d'un juge/reviewer, halt condition déclenchée, checkpoint atteint).

**Pistes techniques :**
- Notification macOS native (`osascript -e 'display notification …'` ou `terminal-notifier`)
  déclenchée par le manager en fin de mission / à chaque jalon.
- S'appuyer sur l'existant : le skill `stop-notify` (hook Stop global → notification macOS) est
  un précédent dans l'écosystème — ici c'est l'inverse, une notification **émise par le manager
  lui-même** aux moments choisis, pas à chaque fin de tour.
- Granularité configurable (fin de mission seulement vs jalons intermédiaires) pour ne pas
  spammer ; vecteur = hook, script posé par l'engine, ou geste direct dans le protocole des
  managers (à trancher — attention : un réglage settings ne voyage pas, cf. régression #38).

**Pourquoi différé :** confort d'usage, pas bloquant ; à cadrer proprement (vecteur de
distribution, granularité, portabilité macOS/Linux) avant tout code.

**Déclencheur de resurgence :** prochaine évolution du team-kernel ou des protocoles managers,
ou demande récurrente de suivi de mission longue distance.

**Ce qui a fermé l'item (2026-08-17).** La **Phase 33** a livré le canal OS portable
(`notify.sh`, macOS / Linux / Windows / WSL, WTCH-03) émis aux fins de nœud du DAG ; son
**annexe D-33-H** a tranché les trois questions que cet item laissait ouvertes, et qui étaient
précisément le motif du report :

- **Granularité** — hiérarchie à deux étages : jalons GSD (fin de phase, fin de milestone) →
  push dans l'app Claude ; fins de nœud de DAG (`done`/`failed`) → toast OS. Jamais à chaque tour,
  jamais sur `running`.
- **Portabilité** — les 4 canaux couverts par `notify.sh`, avec détecteur WSL dans `vf-portable.sh`.
- **Vecteur de distribution, et la mise en garde « un réglage settings ne voyage pas, cf.
  régression #38 » écrite dans cet item** — elle a été *confirmée* et a dicté la solution :
  fichier-sentinelle **scope machine** (patron `stop-notify`), zéro clé de settings, zéro hook neuf,
  parce qu'aucun vecteur d'engine n'existe pour écrire une clé non-hook dans un settings. Défaut
  **OFF** (opt-in), toggle `/vf-notify` (`on`/`off`/`status`/`test`).
- **Le push « émis par le manager lui-même »** que cet item imaginait est **structurellement
  impossible** : `PushNotification` n'existe pas en sous-agent (erreur littérale mesurée). D'où le
  **Pattern H** — le manager émet un `SendMessage(main)`, la session principale pousse.

Modules : `conductor` v1.28.0, `dev-orchestrator` v2.18.0. Renvoi :
`.planning/phases/VFDO-33-watchdog-notifications-des-missions/33-CONTEXT.md` § **D-33-H**.
**Réserve** : livré sur la branche `feat/phase-33-annexe-notifications-opt-in`, **non mergée et non
poussée** au moment de cette clôture — l'item est traité au sens du travail fait, pas encore
distribué.

## check-agents : périmètre des agents tiers (gsd-*, autres chaînes) — CLOS
**Capturé :** 2026-07-26 · **Clos :** 2026-07-27 (Phase 16) · **Origine :** sanity check machine
post-update

`check-agents.sh --strict` sur `~/.claude/agents` remontait 66 non-conformités — toutes sur les
agents `gsd-*` (chaîne tierce qui ne suit pas la charte ADR-044). Fermé par le flag
`--third-party-prefix` (défaut `gsd-`, répétable ; `--no-third-party-prefix` pour le vider) posé
en Phase 16 dans `plugin/conductor/scripts/check-agents.sh` : un agent `gsd-*` n'est plus linté
pour la charte VibeFlow, et une entrée d'allowlist qui matche le préfixe est réputée résolvable.
**Vérifié empiriquement le 2026-07-27** : `check-agents.sh --strict --agents-dir="$HOME/.claude/agents"`
sort désormais en exit 0 (34 agents `gsd-*` exclus, 0 erreur, 26 warnings résiduels sur des agents
réels non-`gsd-*`, hors périmètre de cet item). Sans le flag (`--no-third-party-prefix`), les
erreurs `gsd-*` réapparaissent (169 lignes ✗/⚠) — confirme que c'est bien le flag qui ferme le
faux positif, pas une coïncidence de version.

## Skill-installer global (multi-agents) — CLOS

**Capturé :** 2026-06-04 · **Clos :** 2026-09-15 (Phase 34, spike SKIL-01, `34-SPIKE-SKIL.md`) ·
**Origine de la clôture :** déclencheur consommé le 2026-06-05, dormi 7 semaines, réduit à un
cadrage go/no-go par le milestone.

**Clos le 2026-09-15** (verdict NO-GO, arbitrage Samuel, AskUserQuestion session principale,
2026-09-15).

**Ce qui a fermé l'item (2026-09-15).** Spike mesuré par exécution (pas par lecture de doc) :
un sous-agent doté de l'outil `Skill` découvre déjà, sans rien d'autre, un skill posé par le
canal `/plugin` natif en scope user (`CAS-A: ATTEINT`, sentinelle obtenue littéralement ;
contrôle négatif `ECHEC`, appareil de mesure validé). Le différenciateur de F8 (« rendre les
skills disponibles à tous les agents ») n'existe plus techniquement au niveau du canal — voir
`34-SPIKE-SKIL.md` § « Canal vs architecture » pour la distinction complète avec la question,
distincte et hors périmètre, de savoir si tous les agents VF ont l'outil `Skill` (non, 18/25 ne
l'ont pas — dont 17 workers `vf-internal: true` cloisonnés Pattern 12 et 1 orchestrateur exposé
non cloisonné, `vf-test-orchestrator` — choix d'architecture, pas un trou de canal). Zéro ligne
de code
d'installeur écrite (D-09). Renvoi : `.planning/phases/VFDO-34-gaps-agency-agents-cadrage-skill-installer/34-SPIKE-SKIL.md`.

Historique d'origine (2026-06-04), pour mémoire : étendre l'approche d'install à toggles
(plugin + skill `/vibeflow-install`) à l'**installation de skills globaux disponibles pour tous
les agents** — un « skill-installer » générique. Clôturé sur mesure : le canal `/plugin` natif
atteint déjà cet objectif, sans second système à construire.

## Posture de protection de `main` — TRANCHÉ : phase dédiée à inscrire (2026-09-15)

**Décision** : arbitrage Samuel, AskUserQuestion session principale, 2026-09-15 — ouvrir une **phase
dédiée « posture de protection du dépôt »** (prochain numéro libre, 41). L'inscription au ROADMAP est
faite par la session principale **après le merge de la PR #67**, délibérément, pour ne pas créer de
conflit sur `ROADMAP.md` avec la branche de la Phase 25. Le présent item est la trace côté branche ;
il cesse d'être un `human_needed` et devient le cahier des charges de cette phase.

**Constat mesuré** (audit de la vague 3, Phase 25) : `gh api repos/picmakpro/vibeflow-os/rulesets`
rend `[]`, et l'endpoint de protection classique rend 404 avec des permissions `push:true,
admin:false` — cohérent avec « aucune protection configurée », pas avec un refus d'accès. `main`
n'est donc protégée par rien.

**Conséquence** : **tout gate in-repo de ce dépôt est neutralisable depuis la PR qu'il juge.** Une
même PR peut modifier un gate, sa suite de tests et l'étape CI qui l'invoque. Le cas est concret pour
la Phase 25 (`check-instruction-budget.sh` + `test-check-instruction-budget.sh` + l'étape du job
`gates`), mais le risque est **structurel et antérieur** : il vaut identiquement pour
`check-divergence.sh`, `check-agents.sh`, `check-version-sync.sh` et tous les autres. Aucun threat ID
du registre STRIDE de la Phase 25 ne le nomme — il dépasse le périmètre d'une phase de gate.

**Forme attendue** : un ruleset exigeant la **CI verte avant merge** sur `main`. À poser **dans une
phase à part, jamais au passage d'une mission** : changer les règles du merge pendant qu'une PR est
ouverte modifierait les conditions de cette PR en cours de route.

**Points à instruire dans la phase 41** : interaction avec la discipline de release du `CLAUDE.md`
(le gate `check-release-tag` est déjà `main`-only et échoue par construction au merge, rerun requis
après le tag) ; sort du hook `pre-push` optionnel (`scripts/hooks`) ; effet sur les hotfix urgents.

**Déclencheur de reprise** : inscription au ROADMAP par la session principale après le merge de
la PR #67.

**Statut partiel (2026-09-18, Phase 41) :** la phase a été ouverte et cadrée, sa prémisse s'est
renversée (accès admin absent, cf. l'item ci-dessus), et le cahier des charges est désormais
scindé — la partie in-repo est traitée par ADR-072 (`docs/ADR.md`), la partie côté serveur reste
au premier item de cette page. La forme attendue décrite ici (« un ruleset exigeant la CI verte
avant merge ») n'existe pas encore : cet item n'est pas marqué achevé.

## ADPT-06 — canal `hooks`/`plugins` du dépôt jugé jamais répété — RÉSORBÉ (2026-09-24)

**Capturé :** 2026-09-24, audit de clôture du jalon `fiabilite-v1.0` (compartiment `fiabilite`,
`.planning/workstreams/fiabilite/REQUIREMENTS.md`). **Résorbé :** 2026-09-24, preuve
`.planning/workstreams/fiabilite/phases/VFDO-38-portabilit-multi-runtime-livraison-canal-d-install-migration/38-ADPT06-HOOKS-REPETITIONS.md`
(commit `78648ca`) — répétitions du canal `hooks`/`plugins` menées (5 runs, marqueur `0/5`), deux
gates indépendants vérifiés séparément (confiance par défaut du projet/des hooks ; les deux
drapeaux `features.hooks=false`/`features.plugins=false`). Limite déclarée dans ce même document :
dépôt jugé jamais trusté et sans `--dangerously-bypass-hook-trust`, un seul type de hook mesuré
(`SessionStart`), pas de plugin réel construit, non reproductible en suite automatisée (appel
réseau requis).

**Le défaut :** ADPT-06 exige la preuve de fermeture du canal d'injection en RÉPÉTITIONS (≥ 3 runs,
marqueur attendu 0/N), « jamais en un run » — livrée et cochée sur cette base. Mais la preuve
mesurée (`0/5`) ne couvre QUE le canal `skills`/`AGENTS.md` du dépôt jugé. **Le second canal
possible d'injection, `hooks`/`plugins` du même dépôt jugé, n'a jamais eu ses propres
répétitions** — voir le commit `3b7de24`, qui porte la preuve du premier canal sans toucher au
second. L'exigence est donc livrée pour un canal sur deux, pas les deux comme son intitulé («
fermeture du canal d'injection ») pourrait le laisser lire.

**Piste de fix :** reproduire le protocole de répétition déjà validé pour `skills`/`AGENTS.md`
(≥ 3 runs sur le banc témoin, marqueur attendu 0/N) pour le canal `hooks`/`plugins`. Même
discipline, même seuil de non-déterminisme (2/3 mesuré sur l'autre canal — un run propre ne prouve
rien).

**Déclencheur de reprise :** avant toute déclaration publique de fermeture COMPLÈTE du canal
d'injection du dépôt jugé (les deux canaux), ou la prochaine fois qu'ADPT-06 (ou son équivalent)
est rouvert pour un autre motif.

## Pour Samuel — hooks GSD introuvables dans les worktrees (constaté 2026-09-28) — CLOS (Phase 41.3, 2026-09-30)

**Capturé :** 2026-09-28, pendant la mission de la Phase 44 (worktree `gouvernance-44`). Arbitrage
de l'inscription : Willy, session principale, 2026-09-28 (relayé par la session principale au
manager de mission). Hors périmètre de la Phase 44 : ni l'installeur ni `merge-hooks.sh` ne sont
touchés ici.

**Le défaut** : les hooks posés dans `settings.local.json` pointent vers
`"$CLAUDE_PROJECT_DIR"/.claude/hooks/gsd-context-monitor.js`. Dans un worktree
`.claude/worktrees/<nom>`, `CLAUDE_PROJECT_DIR` vaut le worktree ; or `.claude/*` est ignoré par
git (`.gitignore:24`) et n'y est donc pas recopié. Résultat : « Stop hook error: Cannot find
module » (non bloquant), et le moniteur de contexte GSD ne tourne pas dans les worktrees.

**Portée élargie (constat du 2026-09-29, session principale)** : ce n'est pas seulement le
moniteur de contexte. Les 22 commandes de hooks de `settings.local.json` qui visent
`"$CLAUDE_PROJECT_DIR"/.claude/hooks/*` ou `${CLAUDE_PROJECT_DIR}/.claude/scripts/*` sont dans le
même cas, dont des **gardes** : `gsd-secret-read-guard.js`, `gsd-write-guard.js`,
`gsd-read-guard.js`, `gsd-prompt-guard.js`, `gsd-worktree-path-guard.js`, et
`guard-driver-lock.sh`. Un garde qui échoue sans bloquer est un garde désactivé : dans un
worktree, ils ne protègent rien, sans aucun signal au-delà du message d'erreur.

**Mécanisme retenu** (2026-09-29, Phase 41.3, plan 02) : `.worktreeinclude` (syntaxe .gitignore,
documentée : code.claude.com/docs/en/worktrees, /hooks#worktreecreate) recopie `.claude/hooks/` et
`.claude/scripts/` dans tout worktree créé par Claude Code. Écartés : un hook `WorktreeCreate`
(réimplémente la création git et désactive `.worktreeinclude`) ; les liens posés par l'installeur
(il tourne avant les worktrees) ; le repli sur le checkout principal (même défaut de localisation).

**Limites** : copie figée à la création ; `git worktree add` manuel non couvert ; `guard-driver-lock.sh`
sous EnterWorktree vise le checkout principal (entrée suivante). Pose chez les labs : faite par l'installeur (Phase 41.3, plan 03, 2026-09-30).

**Propriétaire à la relecture :** Samuel (installeur, polarité fiabilité).

**Déclencheur de reprise :** la prochaine évolution de l'installeur ou de `merge-hooks.sh`, ou la
création d'un worktree où le contournement n'a pas été posé.

