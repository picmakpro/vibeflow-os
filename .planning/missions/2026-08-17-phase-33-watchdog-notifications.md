# Mission — Phase 33 « Watchdog & notifications des missions »

**Date** : 2026-08-17 · **Branche** : `feat/phase-33-watchdog-notifications` · **Base** : v2.55.0,
conductor v1.26.0 · **DAG** : `.planning/MISSION-33.dag.json` (20 nœuds, 15 done, 1 ready, 4 blocked)
**Périmètre atteint** : cadrage → plans → **deux tours complets de plancheck externe** → correction.
**Non fait** : l'exécution des plans (vagues 1-3), la revue, l'hygiène documentaire.

## Ce que la mission a produit

| Livrable | Fichier |
|---|---|
| Cadrage + décisions D-33-A..D | `33-CONTEXT.md` |
| Terrain (surfaces réelles, 3 prémisses démenties) | `33-TERRAIN.md` |
| Spike hooks async (research flag a) | `33-SPIKE-hooks-async.md` |
| Spike canal de notification (research flag b) | `33-SPIKE-canal-notification.md` |
| Sonde exécutée des capacités de hooks | `33-SONDE-hooks.md` |
| Plans exécutables | `33-01` à `33-05-PLAN.md` |
| Verdicts de plancheck externe | `33-PLANCHECK-EXTERNE.md`, `33-PLANCHECK-EXTERNE-2.md` |

## Les deux research flags, levés avant tout engagement

1. **Hooks async / `asyncRewake` : verdict PAS SÛR.** Les champs existent et sont stables, mais
   **aucun hook n'est périodique** — ils sont strictement événementiels, et `asyncRewake` ne
   réveille qu'une session **déjà active**. Détecter une absence de battement au-delà d'un seuil
   demande une horloge que la plateforme ne fournit pas. Conséquence : pas de watchdog in-process.
2. **Canal Windows : WinRT sous `powershell.exe` 5.1**, jamais `pwsh` (PowerShell Core n'embarque
   pas les assemblies WinRT). BurntToast et `msg.exe` disqualifiés. Deux pièges non intuitifs :
   sous WSL `IS_WINDOWS` vaut 0 et `notify-send` est un faux ami qui échoue sur D-Bus ; et
   `osascript` **sort 0 en jetant la notification** quand le terminal n'a pas la permission
   (gsd-2 #2632) — un `exit 0` n'est jamais une preuve de délivrance.
   **La chaîne Windows reste NON PROUVÉE TERRAIN** : la recherche a levé le risque, pas fourni la
   preuve.

## Décisions

| # | Décision | Motif |
|---|---|---|
| **D-33-A** | Progrès = **deux horloges sur le même battement** : `progress_epoch` additif au `meta`, écrit par `dag.sh mark` | Seule option satisfaisant le critère n°2 à la lettre (« vivant mais bouclant ») sans créer de second mécanisme |
| **D-33-B** | Détection **aux moments d'activité**, zéro démon ; ROADMAP amendé en « un stall ne survit pas au prochain geste d'une session VF vivante » | Aucune horloge côté plateforme ; un observateur externe (cron/launchd) n'est pas portable d'un geste sur un milestone Windows-first. **Limite assumée** : machine sans aucune session = silence possible |
| **D-33-C** | Windows livré **testé par shims d'argv en CI Linux** + recette humaine Win10/11 en **condition de clôture, pas gate dur**, rattachée au fil testeurs de l'issue #20 | Pas de machine Windows ; bloquer la phase dessus serait disproportionné |
| **D-33-D** | Le gate d'armement des hooks est **PORT-05 en CI**, pas `check-capability-activation.sh` | Correction apportée par le worker de cadrage et **vérifiée** (`ci.yml` L777, L903) : mon brief initial était faux |
| **D-33-E** (S1) | Découplage des seuils **et** des émetteurs : `STALL_WINDOW` à 900 s sous le TTL, + amendement du protocole de heartbeat dans `mission-flow.md` | Les deux horloges avaient le même émetteur au même instant : STALL était inatteignable en production |
| **D-33-F** (S2) | Point de contrôle **en lecture** au geste `dag.sh mark` | `SessionStart` seul ne voit un stall qu'à l'ouverture d'une session |
| **S1 = option (b)** | Preuve de protocole **financée** : cas D25, `heartbeat` répété sans `mark`, attente bornée en exception explicite à la prohibition `sleep`, STALL constaté **sans toucher au `meta`** | Les 3 cas antidatés ne démontraient rien du protocole ; la prohibition visait les tests de cadence, jamais la preuve d'un protocole |

Reliquat tracé au backlog : **option (c)**, un gate machine sur l'observance de `mission-flow.md` —
*un critère `grep -c` prouve qu'un paragraphe existe, jamais qu'il est observé.*

## Le plancheck externe, troisième démonstration consécutive

| Tour | Plan-checker interne | Vérificateurs frais |
|---|---|---|
| 1 | rien remonté | **6, 10 et 7 bloquants** (≈ 14 distincts) |
| 2 | — | **6 et 4 bloquants** |

**Deux défauts reproduits par exécution**, tous deux verts de bout en bout dans la facture prévue :
- `mark-progress` **effaçait le champ `step`** du meta (`rewrite_meta` réémet la globale `$STEP`,
  jamais la valeur du fichier) — la mutation rouge de la Phase 32 rejouée sur un autre champ ;
- le sous-contrôle de stall était placé **après trois sorties anticipées** : sur une machine saine
  le répertoire de santé n'existe pas, le script sort SAIN, le contrôle **ne tourne jamais** — mais
  les fixtures faisaient `mkdir -p`, donc la suite était verte. Garde aveugle, tous cas verts.

Au second tour, **cinq des six bloquants étaient des régressions de coordination** nées d'avoir
corrigé trois plans en parallèle : collisions de numéros de cas et d'IDs de menace, dépendance
documentée en prose mais pas dans le frontmatter, et un index argv déplacé sous les pieds d'un
autre plan — un suivi littéral aurait **tué silencieusement D-33-F**. La passe de finition a donc
été menée **en série, par un seul worker**.

## État final des plans

| Plan | Vague | depends_on | Menaces | Périmètre principal |
|---|---|---|---|---|
| 33-01 | 1 | — | T-33-01..04 | `driver-lock.sh` (+ suite) |
| 33-04 | 1 | — | T-33-11..15 | `notify.sh` (neuf), `vf-portable.sh` (+ suites) |
| 33-02 | 2 | 33-01 | T-33-05..07 | `dag.sh`, `test-dag.sh`, `mission-flow.md` |
| 33-03 | 2 | 33-01, 33-04 | T-33-08..10 | `check-guard-health.sh` (+ suite) |
| 33-05 | 3 | 33-02, 33-03, 33-04 | T-33-16..23 | `dag.sh`, `test-dag.sh`, `33-CLOTURE-WINDOWS.md` |

Numéros de cas disjoints (33-02 : T34-T40 · 33-05 : T41-T47), registres de menaces disjoints,
graphe de vagues cohérent. **Baseline de non-régression : 64 suites, 64 vertes**, harnais
auto-validé contre le vert à vide (faux échec et pendaison tous deux détectés).

## Ce qui reste ouvert

- **Exécution** des vagues 1 → 2 → 3, puis revue et hygiène documentaire (nœuds posés au DAG).
- **Barrière de commit entre vagues** et **un worktree par plan** au sein d'une vague : le
  protocole de mutation rouge (`commit → mutation → git checkout --`) partage l'index git.
- **Recette humaine Windows** (D-33-C), condition de clôture.
- **Bump `CHANGELOG.md` / `VERSION` du module `conductor` et mise à jour de `vf-dev-manager.md`** :
  explicitement **reporté à la clôture de phase** (consigné dans 33-05, commit `d04db1d`), sur le
  précédent de la Phase 32 qui l'a fait au moment de la release et non plan par plan. Seul
  `mission-flow.md` est pris en charge par un plan (33-02). À ne pas oublier à la clôture : sans
  ce geste, le verbe public `mark-progress` et `notify.sh` n'existeraient dans aucune doctrine lue
  par les managers.
- La chaîne Windows reste non prouvée terrain, l'AUMID arbitraire vs AUMID PowerShell non tranché,
  la latence `powershell.exe` non mesurée — **à ne jamais présenter comme prouvés**.

---

# Exécution (seconde partie de mission)

Les 5 plans ont été exécutés en 3 vagues, **un worktree git par plan** au sein d'une vague — le
protocole de mutation rouge (`commit` → mutation → `git checkout --`) partage sinon l'index git.

| Vague | Plans | Résultat |
|---|---|---|
| 1 | 33-01 ∥ 33-04 | `driver-lock.sh` 151 → **183** · `notify.sh` neuf + **48** · `vf-portable` **16** |
| 2 | 33-02 ∥ 33-03 | `dag.sh` 99 → **123** · `check-guard-health.sh` → **78** |
| 3 | 33-05 | `dag.sh` 123 → **156** · `33-CLOTURE-WINDOWS.md` |

Découverte du parc : **64 → 65 suites** (33-04 est le seul plan qui en ajoute une).

## Le fait marquant : le watchdog a détecté un vrai stall, le nôtre

Pendant l'intégration, `test-check-guard-health.sh` est passé de 75/0 à **66 PASS / 9 FAIL** sans
qu'aucun de ses fichiers n'ait changé. Cause : le sous-contrôle lisait le **vrai** verrou de la
mission en cours, qui était réellement en stall —
```
[mission-watchdog] stall detecte — owner=mission-33 step=vague-3
(progres fige depuis 1296s, heartbeat frais, seuil=900s) — ne JAMAIS tuer (ADR-031)
```
`progress_age 1303 s > 900 s` avec un heartbeat frais à 135 s : **la signature « vivant mais
bouclant », observée en production et non forgée.** C'est la validation la plus forte possible de
D-33-A et de l'arbitrage S1 — et elle est arrivée par accident, contre la mission qui la
construisait.

Le signal était **juste** ; le défaut était l'**isolation des cas de test** hérités (D1-D7 ne
définissaient pas `VF_DRIVER_LOCK` et lisaient `.planning/DRIVER.lock`). Corrigé sans jamais
toucher au détecteur — faire taire ce signal aurait supprimé la capacité même que la phase livre.

## Deux bloquants d'intégration trouvés par le manager, pas par les tests

1. **`notify.sh` en mode 644** — non exécutable, alors que 33-05 l'invoque en exec direct :
   `permission denied, exit=126`, avalé par le `try/except` → notification **jamais émise, en
   silence**. Corrigé en 755 par 33-05.
2. **`check-guard-health.sh` en 644, le jumeau manqué** — même exec direct, même
   `PermissionError` avalée : **D-33-F ne relayait rien**, la détection « au prochain geste »
   (arbitrage S2) était morte. Corrigé, plus **deux cas de discriminance** « ne JAMAIS retirer »
   (D8 et T48) qui exercent les **vrais** scripts, pas des stubs — sans eux la suite restait verte
   sur un mécanisme mort.

## Revue de code (lot 33-01..33-04)

0 bloquant dans le périmètre du diff. **3 majeurs** : `dirname` non canonicalisé dans `notify.sh`
(MJ-1), invariant `STALL_WINDOW < VF_DRIVER_TTL` jamais vérifié au runtime (MJ-3), et flakiness de
`test-notify.sh`. **MJ-1 et MJ-3 sont corrigés** (commit `19f4616`).

Findings **pré-existants**, hors périmètre, dont la provenance a été vérifiée commit par commit :
`save()` de `dag.sh` sans verrou ni écriture atomique (**lost update silencieux** sur un script
conçu pour le dispatch parallèle — le plus sérieux), `sanitize_field()` incomplet sur les
caractères de contrôle, `vf_guard_unavailable()` sans validation d'argument, TOCTOU sur le
`takeover` legacy. **À tracer, non corrigés.**

## Clôture — CI verte, plus aucun bloquant ouvert

**CI verte de bout en bout** (run `32036349041`) : les 4 jobs passent, dont les **65 suites sur
Linux**. Deux gates avaient d'abord rougi, tous deux justes et imputables à la phase :
`check-machine-paths` (deux SUMMARY portaient le chemin absolu du worktree de leur worker, donc le
nom du compte) et `check-version-sync` (les README annonçaient « 64 suites » alors que la phase en
ajoute une 65ᵉ). Corrigés en `f69e6c9`.

**Le gap trouvé par la vérification est fermé (D-33-G, `88975dc`).** `record_progress()` avançait
`progress_epoch` **avant** que `check_stall_signal()` ne relise le lock : le verdict STALL était
structurellement inatteignable au geste `mark`, précisément le point que l'arbitrage S2 avait fait
naître. L'ordre est inversé, la lecture précède le rafraîchissement, les deux restent après
`save(dag)`. Couvert par le cas de discriminance **T49** — mutation prouvée : sous l'ordre fautif
T49.2 rougit alors que T41 et T48 restent verts, donc **seul T49 mord**, ce qui confirme que c'est
bien son absence qui avait laissé passer le trou. Mesure A/B re-jouée par le manager : les deux
chemins convergent sur le même signal, `rc=0`.

**La flakiness est fermée**, et la vraie cause n'était pas celle qu'on croyait : le budget de
`wait_for_file` (3 s → 10 s) était nécessaire mais insuffisant — le poll visait `.argv`, **premier**
fichier écrit par le shim, au lieu de `.count`, le **dernier**, celui que lit l'assertion. Vérifié
par le manager : **15 runs consécutifs verts** sur le code final (contre 2 échecs sur 12 avant).

État final des suites : `test-dag.sh` **161** · `test-driver-lock.sh` **183** ·
`test-check-guard-health.sh` **78** · `test-notify.sh` **50** · `test-guard-driver-lock.sh` **80** ·
`test-vf-portable.sh` **16 ok** · découverte **65**. Module `conductor` bumpé en **v1.27.0**
(minor : deux capacités publiques neuves).

**Verdict des 4 critères : ATTEINTS**, avec une seule limite assumée — la chaîne Windows n'a jamais
été exécutée, faute de machine : c'est une recette de clôture (`33-CLOTURE-WINDOWS.md`), pas une
preuve.

## Historique — le bloquant qui a été ouvert : `test-notify.sh` flaky

Mesuré par le manager, 5 exécutions consécutives sur le même code :
`47/1 · 46/2 · 47/1 · 48/0 · 48/0`. Le budget de `wait_for_file` (3 s) est trop court sur N4/N5/N11.
Une suite instable en CI installe l'accoutumance au rouge et finit par masquer une vraie régression.
**Le correctif n'a pas pu être livré** : le worker a été coupé par une limite de session externe.
Son travail partiel est préservé (`scratchpad/33-flakiness-partiel.diff`) et la suite a été
restaurée à son état commité.

**Rien ne doit partir en PR tant que ce point n'est pas fermé.**

## État des suites à la clôture

`test-dag.sh` **156/0** · `test-driver-lock.sh` **183/0** · `test-check-guard-health.sh` **78/0** ·
`test-vf-portable.sh` **16 ok** · `test-guard-driver-lock.sh` **80/0** · `test-notify.sh` **flaky
46-48/0-2** · découverte **65**.

## Reste à faire — gates humains uniquement

1. **PR / merge / release racine** : sur demande explicite de Samuel seulement. La branche est
   poussée et verte, rien n'a été ouvert sur GitHub.
2. **Recette humaine Windows** (`33-CLOTURE-WINDOWS.md`), rattachée au fil des testeurs de
   l'issue #20 — condition de clôture, pas gate dur.
3. **Trois zones à ne jamais présenter comme prouvées** : chaîne Windows jamais exécutée, AUMID
   arbitraire vs AUMID PowerShell non tranché, latence `powershell.exe` non mesurée.

**Attention à la cohabitation** : une session parallèle prépare une **release racine v2.55.1**
(hotfix WIN-PATHCONV) dans le même arbre de travail. Aucun de ses fichiers n'a été commité par
cette mission — l'index du dernier correctif a été construit depuis `HEAD` plutôt que depuis
l'arbre, précisément pour ne pas emporter son travail en vol.

## Note de conduite

Trois workers se sont arrêtés **en silence**, travail non commité, sans rapport — mode de
défaillance que cette phase existe précisément pour supprimer. Chaque cas a été rattrapé en
constatant le **disque** puis en réveillant l'agent ; deux fois le travail a dû être commité par le
manager après relecture. C'est un argument de terrain en faveur du watchdog, et il mérite d'être
versé au dossier de la phase.
