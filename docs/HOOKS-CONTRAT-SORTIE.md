# Contrat de sortie des hooks VibeFlow — et inventaire recompté du parc

**Document DURABLE** (pas un artefact de phase) : la polarité gouvernance (Willy) en hérite pour sa
propre migration en forme exec des 20 entrées qui lui restent (§7 du contrat PR #29). Produit par
le plan `VFDO-30-04` (Portabilité Windows II, PORT-03), le 2026-08-15 ; l'inventaire est mis à jour
par le plan `VFDO-30-09` (ajout de la 26e entrée, `check-hook-paths.sh`), le même jour.

---

## 1. Le contrat de sortie

À la frontière du **harness** Claude Code (pas à l'intérieur d'un script), trois codes et rien
d'autre :

- **0** = rien à signaler, OU un signal a été émis normalement (le cas nominal du hook).
- **non nul** = le script n'a pas pu faire son travail — une vraie erreur, jamais un signal
  déguisé.
- **2** — réservé au blocage explicite par le harness (`PreToolUse`/`Stop`/`UserPromptSubmit`
  peuvent bloquer l'appel d'outil ou l'arrêt de session sur ce code précis) — n'est **jamais**
  émis involontairement par un script qui ne veut pas bloquer.

Le contrat de signaux **interne** posé par la Phase 17 (exit 3 = silence volontaire, exit 0 =
signal émis, exit 64 = erreur d'argument) **reste valide À L'INTÉRIEUR des scripts** — ce plan ne
le touche pas. Ce qui change, c'est sa **traduction vers le harness** : `|| true` en forme shell
absorbait tout aveuglément ; en forme exec, cet opérateur n'existe plus, donc chaque script doit
porter lui-même sa traduction.

## 2. La règle de traduction — conditionnée, jamais globale

La traduction du code de silence interne (3) vers 0 est **conditionnée au drapeau de mode hook
(`--hook`)**, jamais un renommage global. Sans le drapeau (CLI, suites de tests), **tous les codes
restent inchangés**.

**Pourquoi** : la CLI (un appelant manuel, `gsd-progress`, un script tiers) et les suites de tests
existantes testent ces codes directement — `rc=3` explicitement asserté. Un renommage global
`exit 3` → `exit 0` casserait ces deux usages. Le point de traduction doit vivre en un seul endroit
nommé (`hook_exit`, voir la tâche 2 de ce plan), déclenché uniquement quand `--hook` est posé.

Aucun lanceur intermédiaire (`run-hook.sh <script>`) n'est introduit : il réintroduirait une
indirection shell qui contredirait l'objectif même de la forme exec sous Windows (D-06).

## 3. Le silence est un contrat de FLUX, pas seulement de code

Sur `SessionStart`, la documentation officielle Claude Code confirme que le **stdout d'un hook
qui sort en 0 est injecté comme contexte de session** — pas seulement journalisé en debug. Un
chemin nominal silencieux doit donc avoir un **stdout strictement vide** (zéro octet), pas
seulement un code de sortie 0 : une ligne vide accidentelle, un warning non redirigé, romprait le
silence promis même à code de sortie correct.

Les diagnostics humains (`say()` et équivalents) vont systématiquement sur **stderr**, jamais sur
stdout — c'est déjà la convention en place dans les 4 scripts du périmètre dev (task 2 de ce plan
le vérifie et le corrige si besoin).

### 3 bis. Quand le stdout n'est PAS vide : un seul objet, encodé

Le silence est le chemin nominal, mais un hook qui a quelque chose à dire est soumis à une
seconde règle, tout aussi contraignante :

- **UN SEUL** objet JSON par exécution. Le harness parse en strict : deux objets concaténés sur
  stdout, même individuellement valides, forment un document invalide et lèvent « Hook output
  looks like a JSON object but is not valid JSON ». Un script dont plusieurs fonctions émettent
  chacune leur objet doit donc les agréger avant de rendre.
- **Encodé par un encodeur**, jamais par concaténation de chaînes (`json.dumps`, `ConvertTo-Json`,
  `jq -n`, `JSON.stringify`) — sans quoi un guillemet, un backslash ou un retour à la ligne dans
  une valeur casse le document.

⚠ **Piège de vérification** : `jq` ne suffit PAS à valider un stdout de hook. `jq` lit un *flux*
d'objets et accepte donc sans broncher `{...}{...}`, que le harness rejette. Vérifier avec un
parseur de **document** (`json.loads`, `JSON.parse`) :

```bash
bash <hook> | python3 -c 'import json,sys; json.loads(sys.stdin.read() or "{}")'
```

C'est exactement ce trou de vérification qui a laissé passer le défaut de l'entrée #18 : le §3
ci-dessus n'avait été appliqué à cette entrée que sur son *code de sortie*, jamais sur son flux.

## 4. L'inventaire — 29 entrées, recompte machine

Commande de recomptage (fait foi, D-08) :

```bash
python3 -c "import json,glob; n=sum(len(h.get('hooks',[])) for f in sorted(glob.glob('plugin/*/hooks/hooks.json')) for gs in json.load(open(f))['hooks'].values() for h in gs); print(n); assert n==29, n"
```

Rendue le 2026-08-17 : `28` (27 recomptées plus tôt le même jour par le plan `32-03`, plus 1 :
l'entrée n°28, `check-guard-health.sh`, `SessionStart · startup`, posée par le plan `32-05`
(QUAL-01, le « hook doctor » spécifié depuis le 2026-08-02 et jamais écrit). Née en forme exec
(D-32-C), **une seule entrée** (pas de piège d'idempotence cross-matcher ici : `SessionStart` du
module `conductor` n'a qu'un seul groupe `startup`, cette entrée s'y ajoute simplement). L'entrée
n°27 (`guard-driver-lock.sh`, matcher `Bash|Write|Edit`, plan `32-03`) est inchangée : **une seule
entrée, pas deux** — D-32-05 envisageait deux entrées séparées (matcher `Bash`, matcher
`Write|Edit`) mais cette forme s'est avérée EMPIRIQUEMENT incompatible avec la purge d'idempotence
cross-matcher de `merge-hooks.sh` (elle retire toute entrée référençant les mêmes scripts dans
TOUS les groupes de l'événement de la cible — la seconde entrée installée supprimait
systématiquement la première). Voir `32-03-SUMMARY.md` pour la reproduction complète. Rendue le
2026-08-18 : `29` — l'entrée n°29, `check-requirements-survival.sh`, `SessionStart · startup`,
posée par le plan `18-01` (LEDG-02, survie du ledger d'exigences à la clôture d'un jalon), ajoutée
au même groupe `startup` UNIQUE de `dev-orchestrator` (même contournement de la dette
d'idempotence cross-matcher que les entrées précédentes de ce module, jamais corrigée ici). Toute
dérive future (une 30e entrée apparue, une entrée disparue) fait échouer cette assertion —
bruyamment, jamais en silence — et impose de mettre à jour l'inventaire et l'assertion
**ensemble**, jamais l'un sans l'autre.

**Colonnes** : module · événement · matcher · script · arguments d'invocation (au-delà du chemin du
script lui-même) · `--hook` accepté (oui/non — et s'il change le CODE de sortie ou seulement le
rendu, quand c'est pertinent) · codes de sortie atteignables **aujourd'hui**, avec cette invocation
exacte · classement **advisory** ou **bloquante**, avec le mécanisme · forme actuelle
(shell/exec) · action requise par la Phase 30 (normalisation, migration, ou rien).

### conductor — 8 entrées

| # | Événement · matcher | Script | Invocation (hors chemin script) | `--hook` | Codes atteignables aujourd'hui | Classement | Forme | Action (Phase 30) |
|---|---|---|---|---|---|---|---|---|
| 1 | PreToolUse · Write | `guard-agent-write.sh` | (aucun) | non | 0 (toujours, fail-open) | **bloquante** — décision JSON `permissionDecision: deny` sur écriture d'agent non conforme (ADR-044), jamais via le code de sortie | shell | rien (déjà 0 systématique, pas de `\|\| true` dans le fragment) |
| 2 | SessionStart · startup | `check-agents.sh` | `--hook --agents-dir=… --skills-dir=…` | oui — n'altère AUJOURD'HUI que le rendu (compact) ; le script documente lui-même « exit 0 toujours » en mode `--hook` | 0 (déjà systématique sous `--hook`) | advisory (SessionStart, ADR-031) | shell + `\|\| true` | rien (déjà conforme au contrat cible) |
| 3 | SessionStart · startup | `check-debug-research.sh` | `--hook --agents-dir=… --skills-dir=…` | oui — même profil que #2 (« exit 0 toujours » sous `--hook`) | 0 (déjà systématique) | advisory (ADR-031) | shell + `\|\| true` | rien |
| 4 | SessionStart · startup | `update-banner.sh` | (aucun — pas de flag `--hook` dans ce script) | n/a | 0 (systématique, « Toujours exit 0 » documenté) | advisory (ADR-031) | shell + `\|\| true` | rien |
| 5 | SessionStart · startup | `check-branch-claim.sh` | `--hook` | oui — **ne change QUE le rendu**, jamais le code de sortie (documenté explicitement dans le script) | 0 (signal), 3 (SAIN/silence), 4 (INDÉTERMINÉ — 3e état hors du contrat 0/3/64, cf. contrat amont §4 « n'a pas pu tourner »), 64 (usage, jamais atteint via ce fragment) | advisory — « ne bloque rien, ne relâche aucun lock » (en-tête explicite, ADR-031) | shell + `\|\| true` | normalisation (30-06) — silence porté par 3/4, pas par 0 ; sans `\|\| true` ces deux codes fuiraient comme erreur harness |
| 6 | SessionStart · startup | `check-workstream-pointer.sh` | `--hook` | oui — documenté explicitement : « ne change AUCUN code de sortie », rendu seul | 0 (conforme), 1 (échec constaté, advisory), 2 (NON VÉRIFIABLE), 3 (silence, non partitionné), 64 (usage) | advisory — « il ne corrige rien, ne bloque rien » (en-tête explicite) | shell + `\|\| true` | normalisation (30-06) |
| 27 | PreToolUse · Bash\|Write\|Edit | `guard-driver-lock.sh` | `args: ["{{VF_SCRIPTS}}/guard-driver-lock.sh"]`, `command: {{VF_BASH}}` | n/a (pas de flag) | 0 (toujours, fail-open à quatre issues — QUAL-01) ; **17** atteignable si aucun interprète n'est joignable (fail-open BRUYANT, `vf_guard_unavailable`) | **bloquante** — décision JSON `permissionDecision: deny` (LOCK-02/03 : commit/checkout/switch/merge/rebase/… Bash, ou écriture Write/Edit sous `.planning/`, D-32-B, d'une session tierce sous lock vivant), jamais par le code de sortie | **exec** (né conforme, D-32-C, contrat PR #29 §5) | née à l'état cible (plan 32-03) — **une SEULE entrée à matcher combiné, pas deux** : voir la note du §4 (purge d'idempotence cross-matcher de `merge-hooks.sh`, découverte empirique du plan 32-03) |
| 28 | SessionStart · startup | `check-guard-health.sh` | `args: ["{{VF_SCRIPTS}}/check-guard-health.sh", "--hook"]`, `command: {{VF_BASH}}` | oui — `--hook` traduit SAIN (3) et INDÉTERMINÉ (4) vers 0 ; le signal (déjà 0) et l'usage (64) ne sont jamais traduits | 0 (silence STRICT si aucun marqueur récent, OU signal — une seule ligne — si au moins un garde du parc a écrit un marqueur récent), 64 (usage, jamais atteint via ce fragment) | **advisory** — le « hook doctor » de QUAL-01 : constate, ne corrige rien, ne bloque rien (ADR-031) ; lecture seule STRICTE du répertoire de santé | **exec** (né conforme, D-32-C, contrat PR #29 §5) | née à l'état cible (plan 32-05) — GÉNÉRIQUE : agrège les marqueurs de TOUS les gardes du parc écrits par `vf_guard_unavailable`, pas seulement ceux de `conductor` |

### consolidator — 7 entrées

| # | Événement · matcher | Script | Invocation | `--hook` | Codes atteignables aujourd'hui | Classement | Forme | Action (Phase 30) |
|---|---|---|---|---|---|---|---|---|
| 7 | PreToolUse · Read | `guard-read-registres.sh` | (aucun) | non | 0 (toujours, fail-open) | **bloquante** — décision JSON `permissionDecision: deny` (lecture hors index-first) | shell | rien |
| 8 | PreToolUse · Bash | `guard-bash-registres.sh` | (aucun) | non | 0 (toujours, fail-open) | **bloquante** — décision JSON `permissionDecision: deny` | shell | rien |
| 9 | PostToolUse · Edit\|Write\|Bash | `post-edit-reindex.sh` | (aucun) | non | 0 (toujours, fail-open : « un hook de maintenance ne casse jamais le flux ») | advisory | shell + `\|\| true` | rien |
| 10 | SessionStart · startup | `seed-registres.sh` | `--project --quiet` | non (pas de flag `--hook` dans ce script) | 0, 1 (gabarits introuvables — module mal installé) | advisory (instanciation mémoire, ADR-032 ; ne bloque rien mais le 1 est aujourd'hui masqué) | shell + `\|\| true` | normalisation (30-06) |
| 11 | SessionStart · startup | `check-registres.sh` | `--hook` | oui — « exit 0 toujours » documenté sous `--hook` | 0 (systématique) | advisory | shell + `\|\| true` | rien |
| 12 | SessionStart · startup | `probe-memory-guards.sh` | (aucun — `--strict` existe mais n'est pas passé par ce fragment) | non | 0 (systématique sans `--strict` : « Silence = tout va bien. Advisory : exit 0 ») | advisory | shell + `\|\| true` | rien |
| 13 | SessionEnd · (aucun matcher) | `archive.sh` | `--async --apply` | non | 0 (mode async : retour immédiat, la tâche réelle se relance en arrière-plan) | advisory | shell + `\|\| true` | rien |

### dev-orchestrator — 6 entrées (périmètre code des plans 30-04/30-07/30-09, 18-01)

| # | Événement · matcher | Script | Invocation | `--hook` | Codes AVANT normalisation (30-04) | Codes APRÈS normalisation (30-04) | Classement | Forme | Action (Phase 30) |
|---|---|---|---|---|---|---|---|---|
| 14 | SessionStart · startup | `check-dev-bootstrap.sh` | `--hook` | oui — avant cette phase, parité d'interface SEULE (n'altérait rien) | 0 (signal onboard/bootstrap), 3 (silence, OU orientation `[gsd-engine]` — sortie non vide, D-14), 64 (usage) | 0 (silence traduit + tous les signaux), 64 | advisory (les 4 SessionStart de dev-orchestrator sont advisory par ADR-031) | shell (migration forme exec : plan 30-07) | **normalisation livrée ici (tâche 2)** ; migration forme exec restant à 30-07 |
| 15 | SessionStart · startup | `discover-unintegrated-docs.sh` | `--hook` | oui — même profil | 0 (au moins un doc non intégré), 3 (rien à intégrer), 64 (usage) | 0 (silence traduit + signaux), 64 | advisory | shell (30-07) | normalisation livrée ici ; migration à 30-07 |
| 16 | SessionStart · startup | `check-doc-drift.sh` | `--hook` | oui — même profil | 0 (seuil atteint), 3 (rien à signaler), 64 (usage) | 0 (silence traduit + signaux), 64 | advisory | shell (30-07) | normalisation livrée ici ; migration à 30-07 |
| 17 | SessionStart · startup | `check-gsd-config.sh` | `--hook` | oui — même profil | 0 (au moins un signal `[gsd-config]`), 3 (aligné/illisible), 64 (usage) | 0 (silence traduit + signaux), 64 | advisory | shell (30-07) | normalisation livrée ici ; migration à 30-07 |
| 26 | SessionStart · startup | `check-hook-paths.sh` | `--hook` | oui — traduit le silence interne (3→0), ne change pas le rendu | sans objet — entrée **née conforme** (plan 30-09) | 0 (silence traduit, et signal `[hook-paths]` sur constat), 1 (« verdict non rendu » — réglages illisibles ou interpréteur Python absent, bruyant sur stderr, stdout vide), 64 (usage) | **advisory** (ADR-031 — constate, ne répare rien, ne bloque jamais le démarrage) | **exec à `command` littéral** (nom nu `bash`, seule entrée du parc dans ce cas) | née à l'état cible (plan 30-09) |
| 29 | SessionStart · startup | `check-requirements-survival.sh` | `--hook` | oui — traduit le silence interne (3→0), ne change pas le rendu | sans objet — entrée **née conforme** (plan 18-01) | 0 (silence traduit, et signal `[ledger-absent]` / `[ledger-illisible]` / `[ledger-outil-absent]` / `[ledger-exigences-disparues]` selon le cas — issue 2bis JAMAIS traduite vers le silence, A-18-08), 3→0 (silence, cran avertissement A-18-02), 64 (usage) | **advisory** (ADR-031 — constate, ne corrige rien, ne bloque jamais le démarrage ; lecteur d'absence, jamais juge de contenu, D-18-10) | **exec** (né conforme, D-01, contrat PR #29 §5) | née à l'état cible (plan 18-01) |

**Dérogation de l'entrée n°26 à ADR-071 §Décision 2** — cette entrée est la SEULE du parc dont le
`command` est un nom nu (`bash`), là où ADR-071 §Décision 2 exige, pour toutes les autres, un chemin
absolu d'interpréteur résolu et vérifié à l'install, **sans clause d'exception**. La raison est le
paradoxe d'amorçage : ce script diagnostique la péremption d'un chemin d'interpréteur figé à
l'install (angle mort assumé de D-01, one-way) — s'il dépendait lui-même de ce chemin figé, il
mourrait exactement dans le cas qu'il sert à détecter. Cette dérogation est autorisée par
l'**approbation humaine de l'addendum du 2026-08-15**, **PAS par ADR-071 elle-même** — ni sa
Décision 2, ni sa section « Ce que cette ADR ne tranche pas » (qui vise la polarité gouvernance), ni
son « Déclencheur de réexamen » (dont la portée est cette même migration à venir, pas ce cas-ci) ne
documentent ce cas. Elle est gardée à la machine par le cas T9 de
`plugin/dev-orchestrator/scripts/tests/test-check-hook-paths.sh` (discriminance prouvée par
mutation). **Reliquat** : un amendement d'ADR-071 — ou une ADR dédiée — est dû pour fermer cet écart
entre la doctrine écrite et le parc réel ; `docs/ADR.md` est hors périmètre du plan `30-09` (geste
humain).

### infrastructure-audit — 1 entrée

| # | Événement · matcher | Script | Invocation | `--hook` | Codes atteignables aujourd'hui | Classement | Forme | Action (Phase 30) |
|---|---|---|---|---|---|---|---|---|
| 18 | SessionStart · startup | `audit-infra.sh` | `--quick --if-older-than=14d --hook` | **oui** — porte à la fois la traduction du silence (3→0, `hook_exit`) **et le rendu du FLUX** (`hook_render`) | 0 (advisory systématique sans `--strict` ; le mode `--strict`, qui rendrait 1/3, n'est jamais atteint ici) | advisory (ADR-031) | shell + `\|\| true` | **stdout corrigé** — les axes écrivent un objet JSON CHACUN, donc `--quick` en émettait DEUX collés : document invalide au parsing strict du harness (`jq` l'acceptait — il lit un flux —, d'où la non-détection). Sous `--hook`, le flux est capturé et rendu en UN SEUL objet encodé (`json.dumps`), émis seulement s'il y a des findings ; stdout strictement vide sinon (§3) |

### planning-core — 6 entrées

| # | Événement · matcher | Script | Invocation | `--hook` | Codes atteignables aujourd'hui | Classement | Forme | Action (Phase 30) |
|---|---|---|---|---|---|---|---|---|
| 19 | SessionStart · startup | `check-planning-state.sh` | `--defer-to-gsd` | non | 0 (frais, ou moteur GSD actif → retrait en silence), 1 (STATE périmé, advisory), 2 (STATE absent, advisory), 3 (`.planning/` absent) | advisory — en-tête explicite : « de façon advisory, jamais bloquant » | shell + `\|\| true` | normalisation (30-06) — le silence n'est pas porté par 0 seul ici, redesign nécessaire |
| 20 | SessionStart · startup | `planning-context.sh` | `--defer-to-gsd` | non | 0 (systématique avec ces arguments — fail-open partout : « toute erreur → exit 0 silencieux ») | advisory | shell + `\|\| true` | rien |
| 21 | SessionStart · startup | `detect-planning-debt.sh` | (aucun) | non | 0 (aucune dette), 1 (au moins un compartiment en dette, **advisory** — documenté explicitement), 3 (racine des compartiments absente) | advisory (en-tête explicite : « advisory, jamais bloquant ») | shell + `\|\| true` | normalisation (30-06) |
| 22 | SessionStart · (aucun matcher, second bloc) | `planning-session-snapshot.sh` | (aucun) | non | 0 (systématique — toutes les branches observées sortent 0) | advisory (baseline d'attribution de session, ne bloque rien) | shell + `\|\| true` | rien |
| 23 | UserPromptSubmit · (aucun matcher) | `planning-task-context.sh` | (aucun) | non | 0 (systématique — fail-open sur toutes les branches observées) | advisory | shell + `\|\| true` | rien |
| 24 | Stop · (aucun matcher) | `guard-planning-updated.sh` | (aucun — **pas de `\|\| true`**) | non | 0 (fail-open, autorise l'arrêt), **2** (bloque l'arrêt — garde-fou de fin de session) | **bloquante** — bloque l'arrêt de session PAR CODE DE SORTIE (exit 2), et **c'est VOULU** : garde-fou machine-enforced « planning à jour avant de s'arrêter » (ADR-040/043/050/055) | shell, sans `\|\| true` | **rien — ne JAMAIS normaliser cette entrée** (la bloquer par exit 2 est le but du script, pas un défaut à corriger) |

### software-architecture — 1 entrée

| # | Événement · matcher | Script | Invocation | `--hook` | Codes atteignables aujourd'hui | Classement | Forme | Action (Phase 30) |
|---|---|---|---|---|---|---|---|---|
| 25 | PreToolUse · Edit\|Write | `guard-file-size.sh` | `args: ["{{VF_SCRIPTS}}/guard-file-size.sh"]`, `command: {{VF_BASH}}` | n/a (pas de flag) | 0 (toujours, fail-open) | **bloquante** — décision JSON `permissionDecision: deny` (Iron Law 300L), et non par son code de sortie qui reste 0 même sur refus | **exec** (déjà migré, contrat PR #29 §5, D-01) | rien (déjà conforme au contrat cible ; PYBIN → `vf_python` reste hors périmètre de PORT-03) |

## 5. Le décompte

| Module | Total | Reproduit par |
|---|---|---|
| conductor | 8 | `python3 -c "import json; d=json.load(open('plugin/conductor/hooks/hooks.json')); print(sum(len(h.get('hooks',[])) for gs in d['hooks'].values() for h in gs))"` |
| consolidator | 7 | idem, `plugin/consolidator/hooks/hooks.json` |
| dev-orchestrator | 6 | idem, `plugin/dev-orchestrator/hooks/hooks.json` |
| infrastructure-audit | 1 | idem, `plugin/infrastructure-audit/hooks/hooks.json` |
| planning-core | 6 | idem, `plugin/planning-core/hooks/hooks.json` |
| software-architecture | 1 | idem, `plugin/software-architecture/hooks/hooks.json` |
| **Total** | **29** | commande de recomptage globale, §4 ci-dessus |

**Les deux entrées bloquantes mises en avant par le plan comme points de vigilance** (le
classement n'est PAS déductible mécaniquement du type d'événement, RESEARCH.md Pitfall 4) :

- **`guard-file-size.sh`** (#25, PreToolUse) — bloque en sortant **0**, via sa décision JSON. Une
  lecture qui ne regarderait que le code de sortie la classerait à tort advisory.
- **`guard-planning-updated.sh`** (#24, Stop) — bloque au contraire **par son code de sortie** (2),
  et c'est le comportement voulu : la seule entrée de tout le parc où « bloquante par code de
  sortie » est une garantie à préserver, jamais un défaut de normalisation à corriger.

**L'inventaire machine complet fait apparaître quatre bloquantes supplémentaires**, du même
mécanisme JSON que #25 : `guard-agent-write.sh` (#1), `guard-read-registres.sh` (#7),
`guard-bash-registres.sh` (#8) et **`guard-driver-lock.sh` (#27 PreToolUse·Bash\|Write\|Edit,
plan `32-03`, LOCK-02/03/05)** — chacune sort toujours 0 et bloque via `permissionDecision: deny`.
Soit **6 entrées bloquantes au total sur les 29** (5 via décision JSON + 1 via code de sortie), et
**23 entrées advisory** (+1 : l'entrée #28, `check-guard-health.sh`, plan `32-05`, +1 : l'entrée
#29, `check-requirements-survival.sh`, plan `18-01` — toutes deux advisory, elles ne bloquent rien,
ADR-031).

## 6. Ce qui reste à la polarité gouvernance

Les **20 entrées gouvernance** (conductor 6, consolidator 7, infrastructure-audit 1, planning-core
6) restent à Willy pour :

- **La migration effective en forme exec** de leurs `hooks.json` — hors périmètre de cette phase
  (§7 du contrat PR #29).
- **L'ajout du drapeau de mode hook** (`--hook`) à leur ligne d'invocation, quand le script ne le
  porte pas encore (`update-banner.sh`, `guard-*-registres.sh`, `post-edit-reindex.sh`,
  `seed-registres.sh`, `probe-memory-guards.sh`, `archive.sh`, `planning-context.sh`,
  `detect-planning-debt.sh`, `planning-session-snapshot.sh`, `planning-task-context.sh`,
  `guard-agent-write.sh`) — c'est cette migration-là, pas cette phase, qui leur donne un point
  d'ancrage pour la traduction.

**Leurs scripts sont normalisés côté script par le plan `30-06`**, sans que leurs fragments
`hooks.json` ne soient touchés par ce plan-là (D-07 : la normalisation de code de sortie couvre
tout le parc, la migration de forme exec reste, elle, bornée au périmètre dev cette phase).
`guard-planning-updated.sh` (#24) est **explicitement exclue** de cette normalisation à venir — son
blocage par code de sortie est voulu et ne doit jamais être traduit.

---

*Produit par le plan VFDO-30-04 (Portabilité Windows II — codes de sortie), 2026-08-15. Inventaire
mis à jour par le plan VFDO-30-09 (26e entrée, `check-hook-paths.sh`), le 2026-08-15, puis par le
plan VFDO-32-03 (27e entrée, `guard-driver-lock.sh`, matcher combiné, LOCK-02/03/05), puis par le
plan VFDO-32-05 (28e entrée, `check-guard-health.sh`, le « hook doctor » générique du parc,
QUAL-01), le 2026-08-17, puis par le plan VFDO-18-01 (29e entrée, `check-requirements-survival.sh`,
survie du ledger d'exigences à la clôture d'un jalon, LEDG-02), le 2026-08-18.*
