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

## Note de conduite

Trois workers se sont arrêtés **en silence**, travail non commité, sans rapport — mode de
défaillance que cette phase existe précisément pour supprimer. Chaque cas a été rattrapé en
constatant le **disque** puis en réveillant l'agent ; deux fois le travail a dû être commité par le
manager après relecture. C'est un argument de terrain en faveur du watchdog, et il mérite d'être
versé au dossier de la phase.
