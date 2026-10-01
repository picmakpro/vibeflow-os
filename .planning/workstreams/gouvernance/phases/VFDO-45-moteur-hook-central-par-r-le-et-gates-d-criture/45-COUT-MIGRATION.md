# Coût de migration des labs réels non migrés — Phase 45 (45-10)

Artefact de phase : il porte les nombres que la référence du modèle (`plugin/planning-core/references/modele-cycles.md`, section
« Coût de migration d'un lab ») s'interdit d'écrire (P45-D-21, P45-D-21a). Aucun nombre de ce fichier ne vit dans le code livré ni dans
la référence ; les chemins sont affichés sous la forme `~/…`.

## Provenance : aucun rejeu réel pour ce fichier (état à sa rédaction), recoupé ensuite par le rejeu final

**Aucun rejeu réel n'a été fait pour ce fichier à sa rédaction** (amendement A5 du manager vf-dev-manager, 2026-10-01 : les rejeux sur
labs réels étaient alors REPORTÉS avec l'armement ; seuls les rejeux sur fixtures et sur banc étaient joués dans ce plan). Tous les
nombres ci-dessous sont repris, tels quels, des relevés existants, sans nouvelle mesure :

| Nombre | Relevé source | Où |
|---|---|---|
| refus conformes de G1 par lab et par motif | `45-REJEU-ETAPE-2.md` | section « Refus conformes au modèle, lab non migré » (tableau par lab et motif) et lignes brutes `COMPTE G1` |
| répartition de ces refus par phase | `45-REJEU-ETAPE-2.md` | même section, tableau « Répartition par phase » |
| refus conformes de G7 par lab | `45-REJEU-ETAPE-3.md` | section « Refus conformes au modèle, lab non migré » (tableau par lab) et ligne brute `COMPTE G7` |
| total cumulé des refus conformes | `45-REJEU-ETAPE-3.md` et `45-REJEU-ETAPE-4.md` | ligne brute `REJEU-ETAPE-3` puis `REJEU-ETAPE-4` |

Réserve de provenance : ces relevés ont été mesurés sur le hook **avant** les lots de correction A, B et C du 2026-10-01 (relevés de
l'étape 2 au commit `630478c`, de l'étape 3 et de l'étape 4 sur les commits de leurs plans). Le **nouveau rejeu réel**, sur des labs au
repos, qui précédait tout armement, devait remesurer ces nombres. **Il est fait** (`45-REJEU-FINAL.md`, commit `708debcb`, 2026-10-01) :
ses lignes `COMPTE` rendent 196 refus conformes pour G1, 6 pour G7 et 202 au total, soit les mêmes nombres que ceux repris ici, avec 0 faux
refus et 0 faux accept ; aucun écart entre les deux mesures. Les nombres du tableau ci-dessous restent ceux des relevés d'étape ; le relevé
final les recoupe.

Reproduction (lecture seule, depuis ce dossier) : `grep -E '^(COMPTE G1|COMPTE G7|REJEU-ETAPE-[234]) ' 45-REJEU-ETAPE-2.md
45-REJEU-ETAPE-3.md 45-REJEU-ETAPE-4.md`.

## Refus conformes au modèle, lab non migré (refus-conforme-modele)

Un refus conforme au modèle est une écriture que le modèle interdit et que le gate refuse : ni un faux refus ni un faux accept
(P45-D-21a). Compté à part ; le seuil d'armement porte sur les faux refus et les faux accepts (0 et 0 sur les quatre relevés).

| Lab | Gate | Refus conformes au modèle (`refus-conforme-modele`) | Motif |
|---|---|---|---|
| `~/jarvis-keystone` | G1 | 196 | 189 : refus conforme au modèle, lab non migré (plan écrit sous l'ancienne discipline) ; 7 : classés par la règle écrite, état dérivé absent, motif pas-de-cadrage |
| `~/BusinessFlow-Lab` | G1 | 0 | aucun |
| `~/jarvis-keystone` | G7 | 1 | `00-doctrine` : non-lab, table D-05 amendée (P45-D-14a) |
| `~/BusinessFlow-Lab` | G7 | 5 | quatre orphelins D-05 (`avma`, `dmflow`, `lead-recovery`, `formation`) et `ProjetFlow-FROZEN-A1` (mémoire sans agent, lecture du manager, 2026-09-29, P45-D-14a) |
| **Total** | G1 et G7 | **202** | 196 (G1) + 6 (G7) ; G6, G5 et ROLE : 0 |

## Cadrages à écrire (G1)

Le coût de migration de G1 est le nombre de phases de forme modèle qui n'ont pas de `CADRAGE.md` (ou dont le registre est ouvert) et dont
un `PLAN.md` est réécrit :

| Lab | Unités concernées | Détail (relevé de l'étape 2, tableau « Répartition par phase ») |
|---|---|---|
| `~/jarvis-keystone` | **21 au plus** | 16 phases au motif « non migré » (189 refus) et 5 phases au motif « pas-de-cadrage » (7 refus), toutes sous l'atelier `20-ateliers/01-marche-offre` sauf une qui est sous le `.planning` racine (cycle `05-le-tunnel`, phase `06-la-cloture-de-la-fiche-produit`) |
| `~/BusinessFlow-Lab` | 0 | aucun refus conforme de G1 |

Lecture prudente : le relevé donne une ligne par phase et par motif, pas la distinction entre « pas de `CADRAGE.md` » et « registre
ouvert » pour les 16 phases « non migré » ; le nombre de cadrages **à écrire** est donc au plus 21 (les cadrages à **clore**, dans le cas
du registre ouvert, s'y ajoutent ou s'y substituent). Les phases au format hérité (193 écritures classées « hérité » par la règle écrite)
passent : G1 ne les refuse pas (limite (j) de la référence). Alternative à un cadrage : une dérogation nominative par écriture
(`deroger-gate.sh`), à usage unique, donc proportionnelle au nombre d'écritures (196) et non au nombre de phases.

## Orphelins à résoudre (G7)

| Lab | Dossiers dont le `.planning/` serait refusé à la création | Remède |
|---|---|---|
| `~/jarvis-keystone` | 1 : `00-doctrine` (aucun agent, aucune mémoire) | pas un lab (P45-D-14a) : ne pas y créer de `.planning/`, ou y poser un agent et une mémoire |
| `~/BusinessFlow-Lab` | 5 : `avma`, `dmflow`, `lead-recovery`, `formation`, `ProjetFlow-FROZEN-A1` | habiter le `.claude/` (au moins un agent ET une mémoire) ou poser un marqueur de projet de code ; ces `.planning/` existent déjà, seule leur création serait refusée |

## Ce que ce fichier ne dit pas

- Aucune mesure propre à ce fichier : les nombres viennent des relevés d'étape, recoupés par le rejeu réel final postérieur aux lots A, B et C (`45-REJEU-FINAL.md`) : voir « Provenance ».
- Aucun nombre de faux refus ou de faux accepts autre que 0 et 0 (ceux des quatre relevés, empreintes d'arbre identiques).
- Aucun état d'armement à la rédaction de ce fichier (les constantes valaient alors `observe`) ; depuis le 2026-10-01 les cinq gates sont armés et G2 avertit (référence, « État d'armement livré » ; SUMMARY 45-10, « Armement en cascade »).
