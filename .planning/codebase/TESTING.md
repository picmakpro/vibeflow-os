# Testing Patterns

**Analysis Date:** 2026-10-02

## Test Framework

**Runner:**
- Bash pur, zéro framework externe. Chaque suite est un exécutable autonome `test-*.sh` avec helpers `ok()/ko()` ou `assert()` maison. Les suites les plus lourdes embarquent un fichier d'aides Python en heredoc quoté (`AIDES="$WORK/aides.py"`) qu'elles invoquent section par section.
- **98 suites** découvertes par le motif `*/tests/test-*.sh` (recompté sur disque au 2026-10-02 : `find plugin scripts -path '*/tests/test-*.sh' | wc -l`) : 87 sous `plugin/`, 11 sous `scripts/tests/`.

**Run Commands:**
```bash
# Une suite (depuis n'importe où — chaque suite se situe elle-même par BASH_SOURCE / dirname "$0")
bash plugin/conductor/scripts/tests/test-dag.sh

# Toutes les suites (la boucle exacte de la CI, job `tests`) — LOURD : ne pas la lancer pour une retouche locale
find plugin scripts -type f -path '*/tests/test-*.sh' | sort | while IFS= read -r t; do bash "$t"; done

# Rejouer une partie d'une suite longue pendant le développement (facultatif, jamais en CI)
VF_GATES_SECTIONS=g6,banc bash plugin/planning-core/scripts/tests/test-planning-gates.sh
VF_GATES_MUTANTS=ECHEANCE bash plugin/planning-core/scripts/tests/test-planning-gates.sh   # sous-chaînes d'identifiants de mutants

# Exit code : 0 si tout passe, 1 si au moins un KO (SKIP non bloquant)
```

## CI — `.github/workflows/ci.yml` (4 jobs, push toutes branches sauf `traffic-data`, plus PR)

**Job `tests` — Suites de tests (découverte non vide) :**
- Pose Node 24 puis le moteur GSD (`npx -y "@opengsd/gsd-core@^1" --claude --global`) : sans lui, les cas 20 et 26 de `plugin/dev-orchestrator/scripts/tests/test-check-gsd-config.sh` ne peuvent rien prouver et ne doivent JAMAIS être dégradés en `skip` ni entourés de `|| true`.
- Canari de forme du moteur GSD (lecture de texte de `check-gsd-config.sh`) : trois discriminants dans un fichier unique, aucun ne peut être vert à vide.
- `find plugin scripts -type f -path '*/tests/test-*.sh'` puis exécution de chaque suite dans un `::group::`. **Contrat de découverte (F13)** : 0 suite découverte = `exit 1` (« vacuous green » refusé). Bilan : `== bilan : N suite(s), M échec(s) ==`.
- Une suite nouvelle est découverte sans toucher `ci.yml` : la poser sous un dossier `tests/` avec le nom `test-*.sh` suffit.

**Job `gates` — Gates de qualité (mode strict)** : `check-agents --strict` sur chaque `plugin/*/agents` et chaque `plugin/*/AGENT.md`, `--resolve-agents=strict` (monde fermé), `check-blueprints`, `check-version-sync`, `check-state-integrity` (fan-out par compartiment de planning), `check-capability-activation`, `check-machine-paths`, `check-instruction-budget`, gates workstream-aware sur arbre partitionné jetable, `check-divergence`, `check-planning-consumers-registered`, G-1 `check-baseline-arbitrage`, G-2 `check-gate-touche`, G-4 `check-affirmation-non-mesuree`, G-3 `check-push-sans-pr` (preuve par fixture puis mesure réelle sur push vers `main`), `check-release-tag` (sur `main` uniquement). Chaque étape asserte sa découverte non vide.

**Job `lab-frais` — install baseline + Gate C (leçon UAT 2026-07-25, F2) :** lab vierge `mktemp -d` + `git init`, fermeture transitive de `conductor` par `plugin/_internal/resolve-deps.sh`, chaque module installé par le **vrai engine** (`VIBEFLOW_CACHE="$GITHUB_WORKSPACE/plugin" VF_SCOPE=project bash plugin/_internal/vibeflow-update.sh install <m>`) ; la baseline doit passer ses propres gates sans intervention.

**Job `lab-frais-arme` — as-installed testing (#38) :** installe la fermeture `dev-orchestrator` (9 modules) dans un lab armé distinct, invoque le gate INSTALLÉ sans surcharge (un exit 2 échoue comme un exit 1), exige un plancher d'au moins deux artefacts armés installés, asserte la forme exec posée dans `settings*.json` (PORT-05) et nomme les deux suites de simulation Windows (`test-windows-crlf.sh`, `test-windows-guards.sh`).

**Piège CI** : le shell des étapes `run:` est `bash -e {0}` — aucun `commande && { … }` nu (un `&&` dont la partie gauche échoue avorte l'étape) : utiliser des `if`.

## Test File Organization

**Location :** colocalisé avec l'implémentation — `plugin/<module>/scripts/tests/test-*.sh` (+ `fixtures/`) ; engine sous `plugin/_internal/tests/` et `plugin/_internal/runtime-adapter/tests/` ; outillage du dépôt sous `scripts/tests/`.

**Répartition des 98 suites :**
| Emplacement | Suites |
|---|---|
| `plugin/conductor/scripts/tests/` (32, +1 sous `plugin/conductor/skills/vf-new-lab/scripts/tests/`) | 33 |
| `plugin/dev-orchestrator/scripts/tests/` | 13 |
| `plugin/_internal/tests/` (10) + `plugin/_internal/runtime-adapter/tests/` (2) | 12 |
| `plugin/planning-core/scripts/tests/` | 12 |
| `scripts/tests/` (gates racine et outillage du dépôt) | 11 |
| `plugin/consolidator/scripts/tests/` | 7 |
| `plugin/software-architecture/scripts/tests/` | 2 |
| business-pilot-bundle, content-bundle, design-orchestrator, growth-bundle, infrastructure-audit, installer, kpi-analyst, skill-creator (`plugin/skill-creator/skills/skill-creator/scripts/tests/`) | 1 chacun |

**Où poser une suite qui asserte sur plusieurs modules :** sous `scripts/tests/` (outillage du dépôt), jamais sous un module : un test de module qui lit un autre module casse dans un lab qui n'installe que l'un des deux (doctrine de `scripts/tests/test-hook-exit-parc.sh` et `scripts/tests/test-role-hook-vs-check-agents.sh`). Une suite qui exige l'installeur réel va sous `plugin/_internal/tests/`.

**Naming :** `test-<script-ou-module>.sh` ; l'en-tête liste les truths ou familles couvertes (`T1`, `R-CMD-01`, `R-REJEU-ETAPE`, …) et le contrat de sortie. Les identifiants de familles portent la décision ou l'exigence d'origine (`GATE-08`, `P45-D-20`, voir `.planning/codebase/CONVENTIONS.md`).

## Suites du hook central de planning (Phase 45)

Le hook central `plugin/planning-core/scripts/planning-hook.sh` (cœur Python embarqué en heredoc, gates G1, G5, G6, G7 et rôle ROLE, G2 avertit) est gardé par cinq suites. Règle commune (P45-D-20) : **le hook est rejoué PAR LA COMMANDE ENREGISTRÉE** — lue dans `plugin/planning-core/hooks/hooks.json` par `json.load` (ou dans le `settings.json` du lab pour la suite installée), puis exécutée TELLE QUELLE sous `/bin/sh -c`, stdin = payload du harnais. Jamais un appel direct au script : c'est ce que le harnais exécute, pas ce que le dépôt déclare.

| Suite | Emplacement | Ce qu'elle garde |
|---|---|---|
| `test-planning-gates.sh` (~4900 lignes) | `plugin/planning-core/scripts/tests/` | La **sémantique des gates** : table d'armement (constantes `ARMEMENT_*` du script = `TABLE_ATTENDUE` de la suite, mise à jour dans le même commit que chaque armement), parseurs `lire_frontmatter` / `lire_registre` ast-identiques à ceux de `recalc-planning.sh`, G2 (avertit par `additionalContext`, jamais `permissionDecision`), G5 (`VERDICT.md`), G6 (fichiers générés et scripts du hook sous `<lab>/.claude/scripts/`), G1 (PLAN sans CADRAGE, contrôle croisé avec `recalc-planning.sh --read-only`), G7 (création d'un `.planning/` dans un dossier nu, marqueurs de projet de code), rôle (juge, manager, worker selon l'allowlist `Agent(...)` / `Task(...)`, F9 = f9-allowlist), non-influence de l'environnement (`R-ENV-*`, P45-D-12a), commandes `deroger-gate.sh` et `poser-verdict.sh`, canary (`R-CANG-*`), banc texte `fixtures/gates-banc.txt` (204 directives `@@ ecriture`), et la **référence du modèle** (`R-REFERENCE` : la section « Hook central et gates d'écriture (Phase 45) » de `plugin/planning-core/references/modele-cycles.md` est identique au code livré, limites (a) à (ae) comprises). Les cas de gate tournent sur des copies dont les `ARMEMENT_*` sont FORCÉS (`copie_forcee(..., "armed"|"observe")`), jamais sur l'état livré. Sections : `VF_GATES_SECTIONS`. |
| `test-planning-hook-registered.sh` (~1570 lignes) | `plugin/planning-core/scripts/tests/` | La **couche shell de la commande enregistrée** (`hooks.json`) : une seule entrée `PreToolUse`, forme shell, matcher `Write\|Edit\|NotebookEdit\|Bash\|Agent\|Task`, `timeout` 20 (`R-CMD-01`) ; pose/retrait par `plugin/_internal/merge-hooks.sh` (idempotent, `settings.json` jamais `settings.local.json`) ; lab dev = stdout d'octet vide et code 0 (GATE-10) ; lab adhérent avec script absent, `python3` absent, faute en phase A ou B du script = **deny** (fail-closed), `Bash` ouvert (limite déclarée P45-D-06b), jamais code 2 (P45-D-08) ; corpus au plancher déclaré `PLANCHER_MIN = 49` (un corpus vidé rougit) rejoué en modes A (script réel) et C (script absent) ; `R-PERF` (5 Mo), `R-BORNE` (valeur > 4096 caractères non parcourue, refus libellé), `R-DOUTE` (chemin inanalysable sous `.planning`/`.claude`, `~` développé en HOME). |
| `test-rejeu-gates.sh` (~2250 lignes) | `plugin/planning-core/scripts/tests/` | L'**outil de rejeu en lecture seule** `plugin/planning-core/scripts/rejeu-gates.sh` et le geste sur labs réels `rejeu-reel.sh` (GATE-13) : comptes par gate de **faux refus** et de **faux accept** (`refus-conforme-modele` à part), empreinte des labs identique avant/après, `--etape=n` (les gates d'étape > n sont joués mais comptés `hors-etape`), chemins affichés `~/…` jamais absolus, `node_modules/` ni copié ni rejoué, liens symboliques sortant du lab refusés avant toute écriture, classification totale (`CLASSE-REGLE-ECRITE`), test différentiel sur 64 cellules G1 (`itertools.product`), douze mutants. Tout sur des labs SYNTHÉTIQUES sous un HOME jetable ; les hooks rejoués sont des substituts écrits sous `WORK`, jamais livrés. |
| `test-planning-hook-installed.sh` (~1000 lignes) | `plugin/_internal/tests/` | Le **canary de CI AS-INSTALLED** (GATE-12) : installe `planning-core` dans un lab jetable par l'installeur INCHANGÉ (`plugin/_internal/vibeflow-update.sh`, scope projet puis scope compte dans un HOME jetable), lit la commande POSÉE dans `.claude/settings.json` (ce que le harnais exécute chez l'utilisateur) et la rejoue. Sections `install,modes,g6_scripts,can,can_m2,mutants,desinstall,isolation` : exactement une entrée posée, silence d'un lab dev, deny en mode dégradé (script absent, python absent, script qui sort 1 ou 2), G6 sur les scripts posés (Q-G6 = (b)) mais pas sur `settings*.json` (limite (y)) ni sous `~/.claude/scripts/`, contrôle négatif anti-vert-à-vide (`R-INST-05`), canary de session `check-gates-alive.sh` posé dans le lab, désinstallation sans résidu, vrai `~/.claude` inchangé (`R-INST-ISOL`). Découverte par le `find` de la CI, `ci.yml` inchangé. |
| `test-role-hook-vs-check-agents.sh` (~240 lignes) | `scripts/tests/` | Le **contrôle croisé du rôle** : le hook réimplémente les prédicats I5 (juge) et I6 (manager) de `plugin/conductor/scripts/check-agents.sh` parce que `planning-core` ne dépend d'aucun module. La suite compare le rôle rendu par `planning-hook.sh --classer <agent.md>` à un **oracle différentiel** fait de `check-agents.sh --file` lui-même (variante sans `omitClaudeMd:` → `invariant I5` ⇔ juge ; variante sans `SendMessage` → `invariant I6` ⇔ manager ; sinon `vf-internal: true` ⇔ worker ; sinon producteur) sur tout le corpus d'agents du dépôt (`plugin/*/agents/*.md` + `plugin/*/AGENT.md`, plancher déclaré 31) et sur des fixtures adverses. Deux mutants du hook (`MUT-CROISE-JUGE`, `MUT-CROISE-TOKENIZER`) doivent la faire rougir. |

Rejeu réel (hors CI) : après une correction du hook, rejouer `plugin/planning-core/scripts/rejeu-reel.sh` en lecture seule sur les labs réels ; la mesure attendue est `0 faux refus, 0 faux accept` et des empreintes d'arbre identiques avant/après.

## Test Structure

**Pattern canonique** (cf. `plugin/conductor/scripts/tests/test-dag.sh`, `plugin/_internal/tests/test-vibeflow-update.sh`) :
```bash
#!/usr/bin/env bash
# test-x.sh — en-tête : liste des truths T1..Tn couvertes. Exit 0 si tout passe, 1 sinon.
set -uo pipefail                 # SANS -e : chaque échec est capturé et rendu bruyant
cd "$(dirname "$0")/../.."       # racine du module

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT   # cleanup garanti

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }
# variante : assert "T1.1 — nom" "$output" "sous-chaîne attendue" (compteurs PASS/FAIL)

# ... asserts numérotés T1.x, T2.x ...

echo "== résultat : $pass ok, $fail ko =="
[ "$fail" -eq 0 ]
```

**Pattern des suites du hook** (`plugin/planning-core/scripts/tests/test-planning-gates.sh`) : `ko()` imprime quatre lignes (libellé, `assertion`, `attendu`, `obtenu`) ; les aides Python impriment des lignes `  ✓ …` / `  ✗ …` que le shell RECOMPTE ; une section qui sort non nul sans aucun `✗` fait elle-même un `ko` (jamais un vert silencieux) ; la bannière finale est `== Résultat : N OK · M KO ==` et les suites longues impriment `DUREE s=<n>`. Le résolveur de `python3` rejette le stub `WindowsApps` et se replie sur `python` (ADR-054).

**Isolation :**
- Tout état dans `mktemp -d` ; le vrai `~/.claude` n'est **jamais** touché — scope user testé via `HOME=$(mktemp -d)` RÉASSIGNÉ et EXPORTÉ dans la suite (jamais par un préfixe `HOME=` sur la ligne d'invocation) + snapshot avant/après du vrai `~/.claude` (`test-vibeflow-update.sh`, `test-planning-hook-installed.sh` `R-INST-ISOL`).
- Surcharge par variables d'environnement `VF_*` : `VF_SCOPE`, `VF_MODULES_ROOT`, `VF_DRIVER_LOCK`, `VF_SCRIPTS`, `VF_ARCH_WARN`/`VF_ARCH_BLOCK`, `VF_TARGET_ROOT`, `MEMORY_DIR`, `VIBEFLOW_CACHE`. L'environnement des sous-processus est construit explicitement (`env_sain()`, `ctx.env()`) : jamais d'héritage du shell qui lance la suite.
- Scripts appelés en boîte noire (subprocess réel), verdicts sur exit code + stdout (match sous-chaîne, JSON asserté en substring ou classé par `classer()` : `silence`, `avertit`, `deny`, `autre:…`).
- Portabilité des suites : ni `stat -f/-c`, ni `sed -i`, ni `timeout`, ni `readlink -f`, ni `mapfile`, ni tableau associatif ; comparaisons de fichiers par `cmp -s` ou `comm`, **jamais `diff`** (proxifié et trompeur sur certains postes) ; comptes en `awk`, jamais par un `grep` pipé (le grep proxifié tronque silencieusement).
- Les suites des gates qui lisent git (`scripts/tests/test-check-gate-touche.sh`, `test-check-baseline-arbitrage.sh`) construisent chaque cas dans SON PROPRE dépôt jetable (`mktemp -d`), identité git passée par `git -c`, jamais le dépôt réel ni la config du poste.

## Discipline des mutants (une garde qui ne rougit jamais ne prouve rien)

Toute garde qu'une suite prétend protéger a son **mutant** : une copie du script sous test dont UNE ligne est altérée, rejouée par la suite, qui DOIT rougir. Les ids sont `MUT-<NOM>`; la trace est imprimée (`✓ MUT-<id> TUÉ — …` / `✗ MUT-<id> NON TUÉ` avec `attendu (original)` et `obtenu (mutant)`).

**Quatre conditions d'un mutant valide** (`make_script_mutant` dans `plugin/planning-core/scripts/tests/test-planning-gates.sh`, `make_cmd_mutant` / `mutant_cmd` dans `test-planning-hook-registered.sh`) :
1. **Motif unique** : le motif fixe ne figure qu'à UNE occurrence ; sinon le mutant est refusé (`MOTIF AMBIGU OU ABSENT`).
2. **Texte distinct et syntaxe valide** : `muté != original` (sinon `NON OPPOSABLE (identique)`, un échec, jamais un « mutant satisfait »), `bash -n` / `sh -n` passe, le corps Python compile (`compile(corps_python(muté), …)`). Un mutant qui casse la syntaxe rougirait pour une mauvaise raison.
3. **Cas discriminant** : au moins un cas dont le verdict change entre l'original et le mutant. L'original doit d'abord rendre le verdict déclaré (garde du témoin) ; le mutant doit changer ce verdict (`mutant non opposable` sinon) et rendre un verdict, pas une erreur de syntaxe.
4. **Rejeu licite qui reste vert** : un **témoin** (un cas légitime — par exemple un `Write` neutre dans un lab adhérent, `E01`/`E27` dans la suite de la commande enregistrée) doit rendre le MÊME verdict sous le mutant et sous l'original. Sinon le mutant a cassé autre chose que la garde visée. Même doctrine sur les suites de politique : `plugin/planning-core/scripts/tests/test-workstream-symlink-escape.sh` pose la fixture piégée (discriminante, vérifiée AVANT toute mesure), le mutant (garde retirée → la fuite réapparaît), puis le cas **licite** (un vrai répertoire) qui reste vert à l'octet près, et la cible intacte.

**Une mutation = une preuve.** Ne jamais supprimer ni affaiblir un cas ou un mutant pour faire passer une suite (« Aucun cas ni mutant supprimé ou affaibli » est la formule des commits de la Phase 45). Un nouveau contrôle arrive avec son mutant, dans le même commit.

**Contrôle de la suite par elle-même :**
- Plancher de découverte : `test-role-hook-vs-check-agents.sh` déclare `PLANCHER_CORPUS=31` ; `test-hook-exit-parc.sh` a un compteur de scripts exercés qui fait échouer la suite sous le plancher (vidé, la suite doit échouer sur son propre compteur).
- Contrôle négatif anti-vert-à-vide : `R-INST-05` (réglage vidé de l'entrée → l'assertion rougit, verdict inversé attendu).
- Suites de gates racine : trois issues (PASS / FAIL / BRUYANT) plus SILENCE et USAGE, et des mutants numérotés par comparaison du script (`MUT-1` à `MUT-6` dans `scripts/tests/test-check-gate-touche.sh`).

## Sensibilité à la charge machine

Les suites du hook sont les plus longues du dépôt et mesurent un hook qui se borne lui-même dans le temps. Conséquences à respecter :

- **Le cœur Python du hook a une échéance interne** `ECHEANCE_COEUR_S = 8.0` (code 73, `plugin/planning-core/scripts/planning-hook.sh`) ; le harnais coupe le shell à 20 s (`timeout` de `hooks.json`). Sous forte charge machine (observé en suites à charge 20 à 35, jamais en rejeu réel), le cœur peut dépasser l'échéance AVANT d'imprimer sa décision : la commande enregistrée ferme alors en `deny` (limite (z) dans `plugin/planning-core/references/modele-cycles.md`). Un rouge qui nomme un refus générique du fail-closed pendant une charge élevée est d'abord une charge, pas un défaut : relancer la suite seule une fois la charge retombée avant d'enquêter.
- **Ne jamais discriminer un mutant à l'horloge.** La preuve est le LIBELLÉ et le verdict, jamais un temps (`R-BORNE` : le mutant qui retire la borne perd le libellé « chemin trop long pour etre analyse » quelle que soit la vitesse ; `PLAFOND_BORNE_S = 10.0` n'est qu'une marge de 10x et plus sur le temps mesuré). Quand un mutant dépend d'un coût, rendre ce coût hors de portée de toute machine : `R-DEFS-02` pose trente puces de 32 000 espaces (960 Ko, ~40 s avec l'ancienne expression quadratique, cinq fois l'échéance de 8 s) alors que l'original coûte ~0,04 s ; avec trois puces de 30 000 espaces le mutant survivait selon la vitesse du coureur (3,5 s, 4,19 s, moins de 2 s sur trois runs CI du même commit). Vérifier un tel durcissement par 20 rejeux par cas, à charge faible et sous charge artificielle (16 `yes` en parallèle) : mutants 20/20 coupés, original 20/20 vert.
- **Rendre les cas de minuterie déterministes** : `R-DEFS-06` ramène l'échéance à 0 et fait envoyer un `SIGALRM` au cœur par lui-même (injection `atexit` ou juste après l'émission d'un refus), sans attendre l'horloge.
- **Les timeouts des sous-processus de test sont larges** (120 s par rejeu, 180 à 300 s pour l'installeur, 600 s pour `rejeu-gates.sh` / `rejeu-reel.sh`) : un timeout de suite est une panne de charge ou un blocage réel, jamais un réglage à réduire.
- **Ne pas lancer deux suites du hook en parallèle** avec d'autres travaux lourds sur le même poste ; la CI (`ubuntu-latest`) n'a pas d'autre charge. Les suites impriment `DUREE s=<n>` pour repérer une dérive.

## Mocking

**Framework :** aucun. Substituts par environnement :
- **Env override** pour rediriger les chemins (voir `VF_*` ci-dessus).
- **Copies forcées / mutées du script** sous `WORK` (`copie_forcee`, `copie_armee`, `make_script_mutant`) : l'état d'armement, une constante ou une ligne se réécrit sur la COPIE, jamais sur le script livré ; les hooks « substituts » du rejeu ne sont jamais livrés.
- **Shims sur le PATH** pour simuler Windows sans poste Windows : jq qui émet du CRLF, stub `WindowsApps/python3` factice, PATH sans jq (`plugin/_internal/tests/test-windows-crlf.sh`, `plugin/consolidator/scripts/tests/test-windows-guards.sh`) ; PATH réduit pour le mode `python-absent` des suites du hook.
- **Asserts statiques** sur le source (ex. T4 : aucun `git clone`/`git pull` dans l'engine ; `R-ENV-02` : le cœur Python du hook ne lit aucune variable d'environnement ; `R-REJEU-STATIQUE` : aucun sous-processus autre que bash et `cmp`).
- **Ne pas mocker** : la logique des scripts, les outils POSIX (awk/grep/sed), le vrai I/O fichier, le vrai installeur quand la suite est « as-installed ».

## Fixtures and Factories

- Fixtures statiques dans `<module>/scripts/tests/fixtures/` — mini-registres réalistes (dates figées 2026-01-0x, orphelins/collisions volontaires) : `plugin/consolidator/scripts/tests/fixtures/LEARNINGS-mini.md`, `BLOCKERS-mini.md`.
- **Bancs texte** (pas d'arborescence versionnée : l'installeur pose `fixtures/` à plat et aucun `.planning/` imbriqué n'est versionné) : `plugin/planning-core/scripts/tests/fixtures/gates-banc.txt` et `recalc-planning-banc.txt`. Grammaire : les lignes `@@ lab <nom>`, `@@ dossier`, `@@ fichier <chemin>` (contenu = lignes suivantes), `@@ lien <chemin> -> <cible>`, et `@@ ecriture <outil> <chemin> [agent=] [cwd=] [commande=] :: <attendu> [<gate>]` avec `<attendu>` ∈ `doit-passer`, `doit-refuser`, `avertit`, `silence`. Chemins relatifs au lab : le matérialiseur refuse `/…`, `~…` et `..`.
- Fabriques de payloads et de labs inline (`payload()`, `entree_outil()`, `fabriquer_lab()`, `prepare_module()` dans `test-vibeflow-update.sh`). Pas de factory framework.
- Corpus du dépôt relu par find : `plugin/*/agents/*.md` + `plugin/*/AGENT.md` pour `test-role-hook-vs-check-agents.sh`.

## Gates = tests permanents

Les gates tournent à chaque push (CI) et en local, et suivent tous le **contrat F13** (cible vide → exit 3 INDÉTERMINÉ, jamais un vert). Chaque gate racine a sa suite sous `scripts/tests/` :
- `scripts/check-baseline-arbitrage.sh` (G-1), `scripts/check-gate-touche.sh` (G-2), `scripts/check-push-sans-pr.sh` (G-3), `scripts/check-affirmation-non-mesuree.sh` (G-4), `scripts/check-machine-paths.sh`, `scripts/check-release-tag.sh`, `scripts/check-gsd-core-update.sh`, `scripts/measure-server-rulesets.sh`, `scripts/traffic-snapshot.sh` : suites `scripts/tests/test-<nom>.sh` homonymes.
- `scripts/check-version-sync.sh` — 7 contrôles de synchro versions (triade par module, historique README) ; appelé par `check-release-tag.sh` en pre-push, exercé via `test-check-release-tag.sh` et par `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh`.
- `plugin/conductor/scripts/check-agents.sh --strict` — conformité native des agents (ADR-044), suite `test-check-agents.sh`.
- Gates du conductor et de `dev-orchestrator`, chacun avec `test-check-*.sh` (`check-state-integrity`, `check-workstream-pointer`, `check-instruction-budget`, `check-divergence`, `check-planning-consumers-registered`, …).
- Contrat de sortie des hooks : `scripts/tests/test-hook-exit-parc.sh` (traduction de code sous `--hook` ET flux stdout vérifiés séparément, mutations `m1`..`m3`), `plugin/dev-orchestrator/scripts/tests/test-hook-exit-contract.sh`.
- Guards de hooks, **eux-mêmes testés** : `test-guard-bash-registres.sh`, `test-guard-read-registres.sh`, `test-windows-guards.sh` (consolidator), `test-guard-file-size.sh` (software-architecture), `test-guard-agent-write.sh`, `test-guard-driver-lock.sh`, `test-driver-lock.sh` (conductor), et pour le hook central les cinq suites ci-dessus.

## Coverage

Aucun outil de couverture (non applicable au bash). Proxy : chaque ADR ou phase récente exige ses suites et ses mutants (ex. ADR-054 → `test-windows-crlf.sh` + `test-windows-guards.sh`, rejouables sur macOS/Linux ; Phase 45 → les cinq suites du hook central, compte de cas et de mutants imprimé par chaque suite).

## Ce qui n'est PAS couvert

- **5 modules sans aucune suite** : `validator`, `audit-architecture`, `mobile-test`, `mobile-test-team`, `reference` (modules majoritairement markdown/agents — seuls leurs frontmatters passent `check-agents --strict` en CI ; la prose SKILL.md/AGENT.md n'est pas testée).
- **Scripts racine sans suite dédiée** : `scripts/bump.sh` et `scripts/check-version-sync.sh` (ce dernier exercé seulement comme gate et par deux suites voisines).
- **Windows réel** : simulé par shims (CRLF, stub Store) — aucun runner Windows en CI (étape nommée « Conditions Windows simulées » du job `lab-frais-arme`).
- **Comportement LLM** : le routage des agents, la sémantique des skills et les workflows d'orchestration ne sont validés qu'en UAT sur labs (cf. sections « validé en production » des CHANGELOG).
- **Install marketplace depuis GitHub** : les jobs `lab-frais` et `lab-frais-arme` installent depuis le cache local (`VIBEFLOW_CACHE=$GITHUB_WORKSPACE/plugin`), pas via la fiche marketplace publiée.
- **Hook central sous charge** : le faux refus par dépassement d'échéance (limite (z)) n'est pas reproduit par une suite (non déterministe) ; seul le désarmement du minuteur après décision (`R-DEFS-06`) est prouvé de façon déterministe.
- **Consommateurs de chemin de planning** : un consommateur oublié n'est vu que par le gate `plugin/conductor/scripts/check-planning-consumers-registered.sh` (étape CI du même nom) ; la CI fan-out `check-state-integrity` par compartiment présent (`vf_ws_enumerate`), jamais sur un chemin littéral.

---

*Testing analysis: 2026-10-02*
