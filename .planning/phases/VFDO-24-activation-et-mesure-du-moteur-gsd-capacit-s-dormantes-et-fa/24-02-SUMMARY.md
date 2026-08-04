---
phase: 24-activation-et-mesure-du-moteur-gsd
plan: 02
type: execute
status: complete
date: 2026-08-04
requirements: [GSDA-01, GSDA-04, GSDA-05, GSDA-06]
---

# 24-02 — Zone 2 activée, `hooks.community` refusé

## Divergence plan ↔ mandat (à lire en premier)

Le `24-02-PLAN.md` a été rédigé quand la zone 2 était **différée**. Ce différé a été **levé par
Samuel** avant exécution. Le plan a donc été exécuté **contre son propre verdict** sur trois de ses
cinq `must_haves.truths` :

| `must_have` du plan | Devenu |
|---|---|
| « La zone 2 est DIFFÉRÉE… déclencheur de reprise objectif » | **Caduc** — la zone 2 est activée (ADR-066) |
| « Aucune clé `workflow.windows_enforce` ni `hooks.workflow_guard` n'est posée par ce plan » | **Inversé** — les deux clés sont posées |
| « aucune commande `windows append\|waive\|fixed` n'est invoquée » | **Inversé** — `waive 3` exécuté |
| « `hooks.community` refusé avec sa mesure » | **Tenu**, motif requalifié en mesure de **style** |
| « aucun gate machine de message de commit n'existe ici » | **Tenu** |

Le `<verification>` du plan (« les plans 24-03, 24-06 et 24-12 vérifient que les deux clés sont
**absentes** ») est **à retourner** : ces plans doivent désormais vérifier qu'elles valent `true`.
**Signalé au manager comme finding bloquant pour les lots aval.**

## Ce qui a motivé le dégel

Deux faits re-vérifiés de première main :

1. **Le prérequis était insatisfiable.** `dist-tags.latest` = `1.9.1` (2026-07-31), aucune version
   au-delà ; PR corrective #2975 mergée mais non publiée. Version installée : 1.9.1.
2. **Le risque mesuré était inexistant.** `.planning/WINDOWS.md` (87 lignes) ne porte aucune prose
   libre sous son ledger. Le bug #2893 n'avait rien à détruire.

Doctrine GSD-first : on n'ajourne pas une capacité native contre un risque mesuré inexistant.

## Gestes posés

| Geste | Résultat |
|---|---|
| `windows waive 3` | `open_count` 1 → 0, `waived_count` 0 → 1, fichier **intègre** |
| `workflow.windows_enforce: true` | gate `ship:pre` broken-windows **armé** |
| `hooks.workflow_guard: true` | garde d'enchaînement **armée** (constatée en vol) |
| `hooks.community` | **non posé** — refusé, ADR-067 |
| ADR-066 / ADR-067 | écrites + indexées (154 insertions, 0 suppression) |
| CONCERNS.md | 2 entrées de résiduel (271 → 300 lignes, 0 suppression) |

## Précautions et preuves

**Avant le `waive`** : `WINDOWS.md` re-vérifié propre dans git (SHA de référence `d89a60e`), puis
la commande **répétée sur une copie jetable** (`--cwd` vers un dépôt temporaire) avant d'être jouée
pour de bon.

**Après le `waive`** : 87 lignes avant / 87 après, fence JSON unique et refermée, miroir reparsé
(5 entrées, 4 `fixed` intactes), `git diff` limité à 3 hunks attendus. **Le bug #2893 ne s'est pas
manifesté.**

**Gate `/gsd-ship` — vérifié par la requête même qu'exécute le workflow de ship**, pas par la
lecture de la clé : `gsd-tools loop render-hooks ship:pre` rend désormais
`capId=broken-windows, kind=gate, blocking=true`. **Contre-épreuve** sur une copie de la config
sans la clé : seul `security` s'y arme. La clé est donc bien la cause. Prédicat évalué :
`open_count == 0` en égalité stricte, `onError: halt` (un ledger illisible **bloque**).

**`workflow_guard`** s'est manifestée en vol pendant la rédaction d'ADR-066 (avis « cette édition
ne sera pas tracée dans STATE.md » sur chaque `Edit` de `docs/ADR.md`). Advisory, non bloquante.

## Mesure d'ADR-067, rejouée

Corpus **nommé** : 400 derniers commits sans merge, comptés **en caractères** (un décompte en
octets gonflerait les sujets français et fabriquerait un faux motif).

- **275/400 = 68 %** dépassent 72 caractères
- **65/400 = 16 %** sortent de la liste de types amont
- six types maison confirmés : `release` (29), `planning` (14), `doctrine` (3), `plan`, `bump`, `spec`

Le chiffre « 23/109 » de la phase **n'est pas reproductible** (aucun range git ne rend 109 :
`main..HEAD` = 37, `origin/main..HEAD` = 43). Les deux mesures convergent sur la conclusion ; seul
le corpus diffère. Le nombre non reproductible n'a pas été recopié.

## Commits

| SHA | Objet |
|---|---|
| `7b96e34` | `chore(24-02)` — dérogation de la fenêtre #3 |
| `b3cb402` | `feat(24-02)` — les deux toggles |
| `e5bc089` | `docs(24-02)` — ADR-066 + ADR-067 |
| `5061528` | `docs(24-02)` — CONCERNS.md |

## Reste ouvert

- **ADR-065 n'existe pas** — le registre saute de 064 à 066. Réservé par un autre lot, ou trou à
  combler : appartient au manager.
- La recette humaine XcodeBuildMCP est **dérogée, pas jouée** — à faire sur un lab iOS équipé.
- Tant que gsd-core ≤ 1.9.1, `WINDOWS.md` reste un fichier **purement généré** (cf. CONCERNS.md).
