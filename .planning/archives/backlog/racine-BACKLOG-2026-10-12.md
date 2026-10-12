## Convergence de contenu à l'update de module (manifeste par module) — CLOS (2026-10-12)

Preuve : `8e5f4a0a` (plan 31-05, convergence à l'update) et `7e972678` (release v2.54.0), Phase 31, MANI-01/MANI-03 ; réalisé dans `plugin/_internal/vibeflow-update.sh:451` (chemin `.vibeflow-manifest-<module>`) et `:3105-3125` (suppression des chemins absents du nouveau manifeste, avec backup), suite `plugin/_internal/tests/test-manifest.sh`.

**Capturé :** 2026-07-26 · **Origine :** update réel de la machine 2.23.0 → 2.36.0

L'engine `update` re-matérialise le contenu du module mais **ne supprime pas** les fichiers que
la nouvelle version ne livre plus : les 12 verbes-façades de dev-orchestrator v1.x ont survécu
à l'update v2.1.1 dans `~/.claude/skills/` (nettoyés à la main), ressuscitant le double
catalogue que la bascule agentique a tué. Remède proposé : l'engine écrit un **manifeste des
chemins posés** par module à l'install (`.claude/scripts/.vibeflow-manifest-<module>`), et
`update` supprime les chemins de l'ancien manifeste absents du nouveau (avec backup). Tests :
update d'un module dont une skill a disparu → skill retirée du lab.

## Combler les gaps de couverture inspirés du catalogue `agency-agents` — CLOS (2026-10-12)

Preuve : `bf34d493` (merge PR #66), Phase 34, AGTS-01 ; réalisé dans `.planning/workstreams/fiabilite/phases/VFDO-34-gaps-agency-agents-cadrage-skill-installer/34-AUDIT-AGTS.md:128` (« Gaps refusés ») et `:185` (« Limite de la recherche de preuve »). Le résidu `web-test-team` est suivi par l'entrée AGTS-02 (sujet « AGTS-02 — sortie d'expérimental de `mobile-test`(-team) »), qui reste ouverte.

**Capturé :** 2026-07-20 · **À explorer :** au prochain arbitrage d'extension de périmètre

> **Source :** [`msitarzewski/agency-agents`](https://github.com/msitarzewski/agency-agents) —
> catalogue MIT de 230+ agents-personas Claude Code (`.md` + frontmatter YAML natif), rangés en
> ~12 divisions. Companion app multi-outils :
> [`msitarzewski/agency-agents-app`](https://github.com/msitarzewski/agency-agents-app).
> Modèle « catalogue plat sans orchestration » — **à ne PAS importer tel quel** (densité
> incompatible ADR-029, aucune gouvernance `conductor`). Valeur = **source d'inspiration et de
> personas à distiller**, surtout pour élargir vers des labs non-dev.

**Cadrage.** Le cœur VibeFlow (Engineering, Design, Project Management, Marketing/Content) est
déjà couvert et **supérieur** (orchestration gouvernée vs catalogue). Rien à importer là. Ce qui
suit ne concerne que les gaps réels, distillés depuis leur taxonomie.

**Mapping divisions → modules (au 2026-07-20) :**

| Division agency-agents | Module VibeFlow | Statut |
|---|---|---|
| Engineering | `dev-orchestrator`, `software-architecture` | ✅ Couvert |
| Design | `design-orchestrator` | ✅ Couvert |
| Project Management | `planning-core`, `conductor`, `kpi-analyst`, `consolidator` | ✅ Couvert |
| Marketing / Content | `content-bundle`, `growth-bundle` | ✅ Couvert |
| Testing | `mobile-test`(-team) | 🟡 Mobile only, expérimental |
| Security | `infrastructure-audit`, `audit-architecture` (+ agent `vf-auditer` du dev-orchestrator) | 🟡 Audit oui ; pas incident/compliance |
| Sales | `business-pilot-bundle` (blueprint commercial) | 🟡 Granularité fine à dériver |
| Product | `planning-core` + `business-pilot-bundle` | 🟡 Pas de module product first-class |
| Paid Media | `growth-bundle` (crochet par canal) | 🟡 Crochet oui, blueprints non |
| Support | — | ❌ Manquant |
| Spatial / Game / Healthcare / GIS / Academic | `vf-new-lab` (dérivation) | ❌ Niche, pas de module |

**Pistes priorisées (valeur/effort décroissant) :**
1. **`web-test-team`** — test-team web/e2e (Playwright) calqué sur `mobile-test-team`
   (Pattern 12, workers cloisonnés). Comble un trou de **notre propre chaîne dev** (seul test réel
   = mobile). Usage interne immédiat → priorité #1.
2. **Extensions Sales + Paid Media** des bundles existants — crochets déjà présents
   (`business-pilot-bundle`, `growth-bundle/par-canal`), il ne manque que des blueprints. Leurs
   personas SDR/discovery/proposal et PPC/programmatic sont directement inspirants à distiller.
3. **`SupportFlow`** — nouveau bundle métier (customer service / analytics / legal) si l'on vise
   les labs non-dev. Aucun équivalent aujourd'hui.

**Ce qu'on n'en prend PAS :** le catalogue plat, la densité, tout copier-coller direct dans
`plugin/`. Chaque geste passe par `check-agents.sh` (ADR-044) + ADR-029 + le brainstorming de
périmètre avant tout code.

**Pourquoi différé :** aucun besoin bloquant aujourd'hui ; le cœur couvre l'usage courant. C'est
de l'élargissement de périmètre, à arbitrer selon la stratégie produit.

**Déclencheur de resurgence :** décision d'élargir VibeFlow (test web dans la chaîne dev, ou
ouverture à des labs non-dev Sales/Support/Paid) — six des onze divisions désormais `refuser`
faute de preuve D-02 (voir bloc du 2026-09-15 ci-dessous) : leur déclencheur précis est la
découverte d'un incident documenté, d'une demande externe ou d'un bug récurrent nommé sur l'une
d'elles, pas une simple décision d'élargir dans l'abstrait. `web-test-team` (Testing) reste
`reporter`, sur la dépendance AGTS-02 déjà suivie au ROADMAP (Phase 34).

**Verdict par gap — 2026-09-15 (Phase 34, audit AGTS-01, `34-AUDIT-AGTS.md`).** Matrice
re-mesurée contre le parc réel de `plugin/` (31 fichiers, corpus mesuré identique à la matrice
d'origine ci-dessus) : Engineering / Design / Project Management / Marketing-Content restent
`sans objet` (déjà couverts) ; Testing (`web-test-team`) est `reporter`, sur dépendance à
AGTS-02 déjà suivie au ROADMAP, pas re-arbitrée ici ; les six divisions restantes (Security,
Sales, Product, Paid Media, Support, Spatial/Game/Healthcare/GIS/Academic) sont `refuser` faute
de preuve au sens de la règle de preuve du milestone (D-02) — le ❌/🟡 du catalogue seul ne
suffit pas, il faut un incident documenté, une demande externe ou un bug récurrent, et aucun des
six n'en a un. Zéro agent créé, zéro persona importée (D-01). Détail des six refus, gap par gap,
et condition exacte de réouverture : `34-AUDIT-AGTS.md` §§ « Gaps refusés » et « Limite de la
recherche de preuve ». Aucun item BACKLOG distinct créé par cette note (zéro verdict `combler`,
`34-AUDIT-AGTS.md` § « Items backlog à créer »).

## Budget des SKILL.md et du bootstrap — sans enforcement machine (différé de la Phase 25, 2026-09-15) — CLOS (2026-10-12)

Preuve : `fb097cce` (Phase 43, FABR-09, 2026-09-26) ; réalisé dans `plugin/conductor/scripts/check-instruction-budget.sh:125` (plafond SKILL.md 500) et `:163-208` (découverte des SKILL.md), ratchet du bootstrap `@bootstrap:socle` à `.planning/instruction-budget-baselines.tsv:28`. Le plafond de 2 000 tokens du bootstrap reste un objectif suivi par le sujet « Ramener le socle du bootstrap sous 2 000 tokens (ADR-029) ».

**Capturé :** 2026-09-15, clôture de la première PR de la Phase 25 (mandat vf-coder, plan 25-03).
Hors périmètre de BUDG-01 (D-03) — la phase a délibérément limité sa portée aux agents distribués.

**Le défaut :** ADR-029 borne aussi les `SKILL.md` à 500 lignes et le bootstrap à 2000 tokens, mais
aucun gate distribué ne mesure ni l'un ni l'autre — `plugin/conductor/scripts/check-instruction-budget.sh`
ne couvre que `plugin/*/agents/*.md` et `plugin/*/AGENT.md` (glob à un seul niveau, D-03).

**Déclencheur de reprise :** le gate `check-instruction-budget.sh` existe désormais et son contrat
de mesure (lignes du fichier entier + instructions du body, ratchet par sentinelle) est prouvé.
Étendre sa découverte à un second corpus (`SKILL.md`) est une **modification de portée**, pas une
reconstruction — reprendre ce script comme socle plutôt qu'en écrire un nouveau.

**Écarté, et non différé :** la métrique en tokens estimés pour le budget du bootstrap (piste F3,
`25-CONTEXT.md`) — à ne rouvrir que sur un incident lié à la **taille** du bootstrap plutôt qu'à son
adhérence à la charte de densité.

**Remédiation, pas ici :** l'abaissement des fichiers d'agents distribués les plus chargés (mesurés
`SANS-BASELINE` au rejeu du 2026-09-15, ex. `plugin/dev-orchestrator/agents/vf-dev-manager.md` à
250 lignes) est un geste ultérieur, par lot, chacun abaissant une baseline dans son propre commit —
jamais un livrable de cette phase, et jamais une réécriture « pour passer » le gate.

## Posture de protection de `main` — TRANCHÉ : phase dédiée à inscrire (2026-09-15) — CLOS (2026-10-12)

Preuve : `76985e3f` (sources des rulesets) et `bebd5718` (PROT-01 coché), Phase 41 ; réalisé dans `.github/rulesets/main.json:21` (`pull_request`) et `:36` (`required_status_checks`), ruleset `23892920` `enforcement: active` mesuré par `gh api` le 2026-10-12.

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

## T-25-SC — journal de sécurité de la Phase 25 : TRANCHÉ, geste de clôture (2026-09-15) — CLOS (2026-10-12)

Preuve : `36bca429` (Phase 25, rapport SECURED, 2026-09-16) ; réalisé dans `.planning/workstreams/fiabilite/phases/VFDO-25-budget-d-instructions-et-tage-d-alignement-court/25-SECURITY.md:71` (T-25-SC `closed`, `threats_open: 0`) et `:246` (AR-04).

**Décision** : arbitrage Samuel, AskUserQuestion session principale, 2026-09-15 — le `25-SECURITY.md`
est produit **à la clôture de la phase, après le plan 25-04**, par `/gsd-secure-phase` sur la phase
**complète**, une fois la calibration livrée (donc après la Phase 40). Ce n'est pas une dette
oubliée : c'est un geste de clôture daté et attendu.

**Pourquoi pas maintenant** : la Phase 25 n'est pas close — 3 plans sur 4 sont livrés, `25-04`
(calibration, gravure des baselines, armement de la sentinelle) reste un checkpoint bloquant-humain.
Un journal produit sur une phase à moitié livrée serait à refaire.

**Contexte** : T-25-SC (chaîne d'approvisionnement) est classé `accept` dans le registre STRIDE de la
phase. Le lab a `security_enforcement: true` / `security_block_on: "high"` ; T-25-SC est `low`, il ne
bloque donc pas `/gsd-ship` aujourd'hui. Le précédent d'un accept tracé est établi par
`24-SECURITY.md` et `27-SECURITY.md` (archivés sous `.planning/milestones/agentique-v1.0-phases/`).

**Déclencheur de reprise** : livraison du plan 25-04, avant la clôture de la Phase 25.

## `check-overlaps.sh` : `present()` aveugle à un agent local installé sous son nom de fichier canonique — DIFFÉRÉ — CLOS (2026-10-12)

Preuve : `bfc523c4` (fix), mergé par `6e7c40d7` (PR #119, hors phase GSD), publié dans v2.68.0 ; réalisé dans `plugin/conductor/scripts/check-overlaps.sh:87` (`agent_present_by_name`) et `:126` (appel dans `present()`), test T17 à `plugin/conductor/scripts/tests/test-check-overlaps.sh:256`.

**Capturé :** 2026-09-15, hygiène documentaire de clôture de la Phase 40 (mandat vf-coder). Faiblesse
**préexistante** — non introduite par cette phase, non corrigée ici (« un garde ne se desserre
jamais dans le commit qu'il autorise »).

**Le défaut :** `present()` (`plugin/conductor/scripts/check-overlaps.sh:72-87`) résout un agent
local par correspondance de nom de fichier : `[ -f "$AGENTS_DIR/$ref.md" ] && return 0`. Sur un lab
**installé**, l'agent routeur du dev-orchestrator est posé sous `agents/dev-orchestrator.md` — un
nom de fichier stable, indépendant du nom sous lequel l'agent s'incarne (`vibeflow-head` depuis la
Phase 40, `vibeflow-dev` avant). La frontière ADR-057 entre deux front doors potentiellement
concurrentes (`vibeflow-head` et `gsd-next`, la front door GSD pour qui n'a pas d'agent routeur)
est donc **déjà muette en lab réel** : `present()` ne peut pas la détecter par ce chemin de
résolution.

**Piste de fix :** résoudre `present()` par le **nom** déclaré dans le frontmatter de l'agent
(`name:`), pas par le nom de fichier — même logique que la garde anti-alias T36 de la Phase 40
(motif assemblé, jamais un chemin en dur). La preuve devra être un cas où le nom de fichier et le
nom incarné divergent, rouge avant/vert après.

**Déclencheur de reprise :** un incident réel de recouvrement de front doors en lab installé, ou un
prochain audit `check-overlaps.sh`.


# Détail historique des entrées condensées

Texte INTÉGRAL d'origine, tel qu'il figurait dans `.planning/BACKLOG.md` (blob `9360b7a05d805f0d3ceb37089fdcd73a915eb442`, restituable par `git cat-file blob 9360b7a05d805f0d3ceb37089fdcd73a915eb442`), des quatre entrées ramenées sous le plafond de 40 lignes le 2026-10-12 (arbitrage Samuel, AskUserQuestion session principale, 2026-10-12). Les entrées condensées gardent au BACKLOG leur constat, leur mesure clé, leur état, leur preuve et tous leurs déclencheurs de reprise.

## Les juges d'un artefact de planning ne gardent pas ce qu'on croit — mesuré 2026-09-23

**Statut : constat mesuré, NON réparé. Différé volontairement** — réparer ici élargirait les Phases
41.1/41.2 au-delà de leur périmètre (consigne de la session principale, 2026-09-23). Matrice établie
sur fixtures jetables pendant la mission « généraliser le remède de partition »
(`.planning/missions/2026-09-23-generalisation-remede-partition.md`).

**1. `check-state-integrity.sh --file <chemin ABSOLU>` saute son invariant principal EN SILENCE.**
Le script interpole `FILE_REL` verbatim dans `git show "$AGAINST_REF:$FILE_REL"` (l.201). Un chemin
absolu fait échouer ce `git show` → `HAVE_BASELINE=0` → **l'invariant 1 (non-régression des
compteurs, le cœur d'ADR-063) n'est jamais armé**. Il ne reste que le comptage des lignes `^Phase:`.
Même fichier, même gate, deux verdicts :

```
--file /abs/…/switched/STATE.md                  → « aucune référence à HEAD … invariant ignoré »  rc=0
--file .planning/workstreams/switched/STATE.md   → « current_phase introuvable »                   rc=2
```

C'est un **fail-open silencieux** : le gate rend vert ce qu'il devrait refuser, sans rien signaler.
Découvert **deux fois indépendamment le même jour** — par la mesure de la matrice, et par un
plan-checker frais qui constatait qu'une fixture de mutation était verte des deux côtés. La gravité
tient au contexte : c'est le gate que la Phase 41.1 généralise à **tous** les compartiments.
Généraliser un gate qui sait se taire, c'est généraliser le silence.

**2. `check-dev-bootstrap.sh` est un ROUTEUR, pas un gate.** Son unique `exit 1` (l.241) est **à
l'intérieur du programme `awk`** de `extract_frontmatter` : c'est le code de sortie de l'awk, donc le
statut de retour de la fonction, jamais celui du script. Énumération des `exit` du script :
`{"0":[100,122,301,328], "1":[241], "64":[95,101,108]}`. Deux compartiments identiques sauf
`current_phase` rendent **le même rc=3** ; seul le stdout change (170 octets contre 0). Toute doctrine
ou tout plan qui le compte comme un juge capable de refuser se trompe. *Sémantique inversée à
connaître : pour ce script, `0` est le MAUVAIS état (démarrage incomplet).*

**3. `status` n'est exigé par aucun juge au sens du code de sortie.** Son absence ne coûte que le
signal `[gsd-engine]` (stdout 170 → 0 octet). Gardé par un signal, pas par un verdict.

**4. `REQUIREMENTS.md` dans un compartiment n'est lu par AUCUN juge.** Les cinq juges interrogés —
`check-state-integrity`, `check-dev-bootstrap`, `check-divergence`, `detect-gsd-engine`,
`check-requirements-survival` — rendent des sorties **identiques** avec et sans lui. Le seul script
qui le nomme vise `.planning/REQUIREMENTS.md` à la **racine**, exige un jalon clos, et plafonne à
`rc=3`.

> **Ne pas le retirer de la définition pour autant** (décision de la session principale, 2026-09-23) :
> une exigence sans juge est une **dette à nommer, pas un champ à supprimer**. Le supprimer ferait
> disparaître le besoin en même temps que le contrôle manquant. `REQUIREMENTS.md` reste dans WSAW-05 ;
> ce qui manque, c'est son juge.

**5. Aucune commande unique du moteur ne produit un compartiment pleinement conforme.**
`workstream create` rend un stub (rc=2, `milestone` introuvable) ; `state.milestone-switch --ws`
améliore mais ne suffit pas (rc=2, `current_phase` introuvable) ; `gsd-new-milestone --ws` n'est pas
scriptable (workflow de 719 lignes, 7 gates `AskUserQuestion`, aucun drapeau de bypass). L'état qui
satisfait tous les juges à la fois existe — il demande `state.milestone-switch` **plus** l'ajout à la
main de `current_phase`, `status`, `ROADMAP.md` et d'au moins un dossier de phase cohérent.

**Matrice mesurée** (fixture committée, chemins relatifs) :

| état du compartiment | `check-state-integrity` | `check-dev-bootstrap` | `detect-gsd-engine` | `check-divergence` |
|---|---|---|---|---|
| stub nu (`workstream create`) | **2** | 0 `[bootstrap]` | 3 | 0 |
| après `state.milestone-switch --ws` | **2** | 0 `[bootstrap]` | 0 | 0 |
| idem + ROADMAP + REQUIREMENTS | **2** | 3 (stdout vide) | 0 | 0 |
| conforme au sens WSAW-05 | **0** ✓ | 3 `[gsd-engine]` | 0 | 0 |
| corrompu | **2** | 0 `[bootstrap]` | 3 | 0 |

**TRANCHÉ le 2026-09-23** (décision de la session principale, sur remontée du manager) : le
fail-open du point 1 est **fermé dans la Phase 41.1**. Ce n'est pas un élargissement de périmètre mais
une **condition de validité de ce que la phase livre** — elle multiplie ce gate par N compartiments ;
s'il sait rendre vert en sautant son invariant principal, elle industrialise un faux vert. Fermeture
**au plus petit** : le chemin non résoluble est **rejeté** (code 64, erreur d'usage, message nommant
la cause), jamais converti ni replié ; tout invariant sauté est **annoncé**, quel qu'en soit le
motif ; et la fermeture se prouve par mutation — le même artefact fautif rend rouge en relatif et 64
en absolu, et la fixture de `41.1-06` redevient discriminante.

**Ce qui reste ouvert ici** : même une fois ce cas fermé, la **classe** « gate qui saute un invariant
en silence » reste à balayer sur les autres gates du dépôt. C'est cette classe, et non l'instance,
qui justifie cette entrée au backlog.

## Dérive documentaire et fragilité latente révélées par le gate de budget d'instructions — DIFFÉRÉ (2026-09-15)

**Capturé :** 2026-09-15, clôture documentaire de la Phase 25 (mandat vf-coder), quatre constats
remontés par les juges de cette mission — aucun corrigé ici, tous hors du périmètre déclaré de la
phase (`plugin/validator/`, `.planning/codebase/` et la doctrine de `CONVENTIONS.md` ne sont pas
dans les fichiers livrés par cette phase).

1. **`plugin/validator/README.md:10` affirme « `AGENT.md` = 249 lignes — à 1 ligne du plafond ».
   Mesure réelle : 250** (concordante par `awk 'END{print NR}'` et `wc -l`). La marge est **zéro**,
   pas une. Le `CHANGELOG.md` du même module dit juste (« reste à 250/250 »), seul le README ment.
   `.planning/codebase/CONCERNS.md:79-82` porte le même 249 mais explicitement daté du 2026-07-26 —
   honnête comme relevé d'époque, pas une erreur.
   **Échéance dure : avant l'armement du ratchet en Phase 40** — sans correction, une seule ligne
   ajoutée à `plugin/validator/AGENT.md` fera passer le gate au rouge alors que le README affirmera
   encore qu'il reste de la marge.
2. **`.planning/codebase/CONVENTIONS.md:56`** décrit des codes de sortie « normalisés » (`2` =
   erreur d'usage, `3` = INDÉTERMINÉ) que `check-instruction-budget.sh` inverse délibérément
   (`64` usage, `2` indéterminé, `3` = ratchet non armé — le script cite nommément cette ligne dans
   son en-tête comme la convention dont il s'écarte). C'est désormais le **troisième** gate à
   dévier de cette ligne : « normalisés » ne décrit plus le parc réel.
3. **`.planning/codebase/TESTING.md`** : ligne 98, « les gates suivent **tous** le contrat F13 »
   est faux (trois gates dévient, cf. point 2) ; lignes 29-32, la liste du job `gates` compte 3
   puces pour **10 étapes réelles** (sept manquaient déjà avant cette phase, `check-instruction-budget`
   en ajoute une dixième).
4. **Fragilité latente dans `.github/workflows/ci.yml`, étape `check-instruction-budget`, bloc 1**
   (preuve de discrimination sur fixture) : l'affectation `I="$(bash "$S" --path "$FIX" … | awk
   …)"` s'exécute avant que la baseline de la fixture existe, donc `rc=2` à ce point précis. Sous
   le shell réellement utilisé par GitHub Actions pour cette étape (`bash -e {0}`, **sans**
   `pipefail`), c'est inoffensif et l'étape reste verte — mesuré. Mais si une future édition ajoute
   `shell: bash` en tête d'étape (donc `-eo pipefail` par défaut de ce runtime), l'affectation
   hériterait de `rc=2`, `set -e` tuerait l'étape immédiatement : **exit 2, zéro ligne de sortie,
   aucun diagnostic**. Durcissement suggéré : capturer explicitement le code de retour de cette
   affectation. **Ne PAS ajouter `|| true`** — le plan de la Phase 25 l'interdit formellement sur
   une mesure (le gate doit pouvoir rendre rouge, jamais se replier en silence).

**Pourquoi non corrigé ici :** `CONVENTIONS.md` relève de la doctrine transverse du repo (pas d'un
gate d'une phase) ; `plugin/validator/` et `.planning/codebase/` sont hors du périmètre déclaré de
la Phase 25 (budget d'instructions), qui s'est délibérément limitée à `plugin/conductor/scripts/`,
`.github/workflows/ci.yml` et ses propres traces documentaires.

**Déclencheur de reprise :** le point 1 avant l'armement du ratchet en Phase 40 (dur) ; les points
2-3 à la prochaine révision de `CONVENTIONS.md`/`TESTING.md` ou dès qu'un quatrième gate dévie du
patron F13/codes normalisés ; le point 4 à la prochaine édition de l'étape CI concernée, ou plus
tôt si quelqu'un ajoute `shell: bash` à une étape du job `gates`.

**Statut partiel (2026-09-17, Phase 40.1) :**
- point 1 fermé par le plan 40.1-11 (README `plugin/validator/` réécrit, marge exacte sous le
  plafond révisé) ;
- point 4 fermé par le plan 40.1-03 (mesure de la fixture de l'étape CI à code capturé, sans
  `|| true`) ;
- points 2 et 3 inchangés, toujours différés.

## Protection de `main` côté GitHub — DIFFÉRÉ, en attente d'un accès admin (2026-09-17)

**Constat et arbitrage** : Samuel, AskUserQuestion session principale, 2026-09-17 — le compte
`picmakpro` est celui de **Willy, co-mainteneur du dépôt** : c'est lui qui détient l'admin, pas un
tiers anonyme. Mesure : `gh api repos/picmakpro/vibeflow-os --jq .permissions` →
`admin: false, maintain: false, push: true` sur le compte de Samuel (`samuel-neveugall`).
**Dans cette session, personne ne pouvait poser de ruleset**, ni de revue code owner requise, ni de
PR obligatoire côté serveur — Willy a depuis accepté de poser ce volet lui-même (WhatsApp,
2026-09-23).

**Correction du 2026-09-23** : la séquence écrite plus bas dans cette entrée (« une fois le jalon
`fiabilite-v1.0` clos ») était fausse et circulaire — **PROT-01 appartient à ce jalon**, il ne peut
donc pas se clore avant que les rulesets soient posés. La séquence réelle, demandée par Samuel à
Willy par WhatsApp le 2026-09-23 : Willy pose les rulesets → on prouve → on clôt le jalon → son
jalon à lui (Phase 42) démarre.

**Ce qui est différé, tel quel, sans réécriture** : rulesets de branche et de tags, bypass, revue
code owner requise, PR obligatoire, mesures M-1 à M-4, fermeture de la PR #29, rejeu du flux de
release sous la règle. Décisions D-01 à D-08 du `41-CONTEXT.md` : **suspendues**, pas annulées.
Plans concernés : 41-01 (Task 2 et 3), 41-04 à 41-09, et la partie « sous la règle » de 41-11 à
41-13. Travail conservé : `41-PREUVES.md` (`CONTEXTES-CHECKS` mesuré).

**Déclencheur de reprise** : un accès **admin** au dépôt (droit accordé à un compte de Samuel, ou
geste posé par Willy lui-même sur `picmakpro`). Ce jour-là, la posture visée est déjà écrite :
`41-CONTEXT.md` § Arbitrages, et les plans différés se rejouent dans l'ordre.

**Accord obtenu le 2026-09-23** : Willy a accepté de poser lui-même le volet rulesets sur
`picmakpro` (WhatsApp, 2026-09-23) — geste séquencé **avant** la clôture du jalon `fiabilite-v1.0`
(PROT-01 en fait partie), pas après (correction du 2026-09-23 de la formulation initialement écrite
ici, qui inversait la séquence). Séquence réelle : Willy pose les rulesets → preuve → clôture du
jalon → ouverture du jalon de Willy (cf. Phase 42 du ROADMAP). Le volet reste différé jusqu'à ce
geste ; d'ici là, aucune garde côté serveur n'existe.

**Ce qui reste faisable sans admin** (à arbitrer avec le nouveau périmètre de la Phase 41) : gardes
in-repo visibles et tracées — baseline du budget d'instructions, modification d'un gate ou de
`ci.yml`, détection après coup d'un push direct, durcissement du hook `pre-push`. **Limite de fond,
à écrire partout** : une garde qui vit dans le dépôt peut être modifiée par la PR qu'elle juge ;
sans règle côté serveur, on ne ferme rien, on rend visible et tracé.

**Statut partiel (2026-09-18, Phase 41) :** le périmètre sans admin est livré par les plans 41-14 à
41-19 (trois gardes in-repo — G-1 baseline, G-2 surface de gate, G-3 push sans PR — et la doctrine
ADR-072). Le volet côté serveur ci-dessus reste différé tel quel, son déclencheur de reprise
inchangé ; les décisions D-01 à D-08 restent suspendues. Renvoi : `docs/ADR.md` § ADR-072.

**Rulesets posés — PROT-01 clos (2026-09-23/24).** Willy a posé les deux rulesets sur `picmakpro`
le 2026-09-23 19h56 (`refs/heads/main` id `23892920`, `refs/tags/v*` id `23892922`, tous deux
`enforcement: active`), re-mesurés le 2026-09-24 (session principale puis mandat de clôture,
`REQUIREMENTS.md` § PROT-01, `41-PREUVES.md` § « Clôture PROT-01 »). **Écart consigné, non
corrigé** : le champ `require_extra_approval_for_unattributed_changes: true` est présent côté
serveur sur les deux rulesets (mesuré `gh api repos/picmakpro/vibeflow-os/rulesets/<id>`) mais
absent des sources versionnées `.github/rulesets/main.json` et `.github/rulesets/tags-v.json` —
c'est un défaut posé par GitHub à la création du ruleset, jamais demandé dans les sources, sans
effet observé sur le comportement décrit par PROT-01 (revue code owner + 4 checks requis, refus de
merge hors bypass nommé). La divergence entre le fichier relu et l'état réel reste ouverte :
**déclencheur de reprise** — soit aligner les sources sur la valeur réelle du serveur, soit
demander à GitHub Support pourquoi ce défaut est appliqué sans qu'il figure dans le payload de
création envoyé.

## Pour Samuel — `vf_ws_enumerate` pose `found=1` même quand `cd` échoue (constaté 2026-09-28)

**Capturé :** 2026-09-28, pendant l'audit de la Phase 44 (worktree `gouvernance-44`), correction de
classe lot 7 (`recalc-planning.sh`), reproduit par exécution dans l'environnement maîtrisé exact du
moteur. Motif du report : P44-D-01b (`detect-gsd-engine.sh` et `workstream-policy.sh` restent
INCHANGÉS en Phase 44 — le lot 7 a fermé la conséquence côté appelant, dans `recalc-planning.sh`
seul, jamais dans ces deux fichiers). Voisine de l'entrée précédente (même primitive, même fichier,
même classe de trou plus large) — pas un doublon : le trou de saut de ligne casse le CONTENU d'une
ligne déjà émise, celui-ci fait émettre une ligne alors que l'émission elle-même a ÉCHOUÉ.

**Le défaut** : dans la boucle d'énumération (`workstream-policy.sh:294-307`), pour chaque entrée
retenue (dossier réel, non-lien), la ligne `printf '%s\n' "$(cd "$entry" && pwd)"` puis
`found=1` s'exécutent INCONDITIONNELLEMENT — même quand `cd "$entry"` a ÉCHOUÉ (compartiment sans
bit `x`, permissions dégradées en `000`/`600`/`400`). `cd` échoue, la substitution de commande
`$(...)` capture une chaîne VIDE (le code de retour de `cd` n'est jamais testé), `printf` imprime
une ligne VIDE, et `found=1` est posé quand même — comme si le compartiment avait été énuméré avec
succès. `detect-gsd-engine.sh` (priorité 2bis, `workstream-policy.sh:305-306` côté lecture — même
zone que l'entrée précédente) saute cette ligne vide en silence (`[ -n "$_wsdir" ] || continue`) :
aucune autre ligne ne suit, la priorité 2bis retombe sur la priorité 3/4 et rend le code 3
« terrain libre » SANS AUCUN diagnostic qui distingue ce cas du cas nominal (aucun compartiment).
Mesuré : un compartiment RÉELLEMENT tenu par GSD, mais dont le mode empêche `cd`, devient
indétectable par `vf_ws_enumerate` — le lot 7 ferme la conséquence côté appelant (garde de lecture
qui relance `vf_ws_enumerate` pour de vrai et compare son résultat à l'ensemble réel du disque),
mais la primitive elle-même reste silencieuse sur ce cas précis.

**Mesuré aussi, même lot** : un `STATE.md` (racine ou de compartiment) rendu illisible (mode `000`)
produit le même silence côté LECTEUR — `has_frontmatter_key` (`detect-gsd-engine.sh`) échoue à
ouvrir le fichier, ne trouve donc pas la clé cherchée, et le code de sortie qui en résulte ne se
distingue en rien d'un fichier simplement dépourvu du marqueur. Ce n'est pas un défaut de
`vf_ws_enumerate` elle-même (elle n'ouvre aucun `STATE.md`) mais du même MOTIF, un cran plus loin :
aucun des deux consommateurs de cette primitive ne distingue aujourd'hui « le marqueur est absent »
de « je n'ai pas pu vérifier s'il était présent ».

**Piste durable** : tester le code de retour de `cd` avant le `printf` — `found` ne devrait se
poser QUE si `cd` a réussi ; sur échec, un code de sortie DISTINCT (ni 0, ni le 3 nominal du dépôt
non partitionné) rendrait le cas AUDIBLE plutôt que silencieusement confondu avec « aucun
compartiment ». Même remède de principe pour un `STATE.md` illisible côté `has_frontmatter_key`.

**Coût à volume et fenêtre TOCTOU, mesurés lot 8 (2026-09-28)** — deux limites supplémentaires de
cette même primitive, constatées en construisant la garde de lecture du moteur (`recalc-planning.sh`,
`_lecture_detecteur_fidele`, qui relance `vf_ws_enumerate` pour de vrai à chaque appel du moteur) :
- **Volume** : `vf_ws_enumerate` mesurée à environ 98 secondes à 3000 compartiments — plus du double
  du délai de 30 s que la garde de lecture s'impose (`timeout=30`), qui refuse alors fail-closed
  (`enumeration-execution-en-echec`) plutôt que d'attendre. Un lab partitionné à ce volume de
  compartiments ne peut donc plus jamais écrire par cette voie tant que le volume n'a pas baissé (ou
  que le délai côté appelant n'a pas été révisé) — pas un bug du moteur, mais un plafond de
  performance de `vf_ws_enumerate` elle-même qui devient visible dès qu'un appelant la relance à
  chaque recalcul plutôt qu'une seule fois par exécution du détecteur.
- **Fenêtre TOCTOU** : la garde de lecture et le détecteur lisent le disque INDÉPENDAMMENT, à deux
  instants distincts d'une même exécution — mesuré, 1 écriture sur 15 essais avec un `mv` concurrent
  LOCAL exécuté entre les deux lectures (gsd-security-auditor, 2026-09-28). Résolution durable
  envisagée côté appelant : une seule lecture partagée entre la garde et le détecteur, ce qui
  suppose que `vf_ws_enumerate` (ou `detect-gsd-engine.sh`) EXPOSE son résultat d'énumération à
  l'appelant plutôt que de le refaire deux fois en interne à chaque appel — hors périmètre de la
  Phase 44 (P44-D-01b), à cadrer avec la piste durable ci-dessus si `workstream-policy.sh` évolue.

**Propriétaire à la relecture :** Samuel (propriétaire de `workstream-policy.sh`, Phase 41.1).

**Déclencheur de reprise :** la prochaine évolution de `workstream-policy.sh` ou de
`detect-gsd-engine.sh`, ou un incident où ce trou a masqué un compartiment réel dont les
permissions étaient dégradées.

