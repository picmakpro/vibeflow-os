# Phase 44 — Passage en lecture seule sur deux labs réels du poste

**Date** : 2026-09-28
**Moteur** : `plugin/planning-core/scripts/recalc-planning.sh` v2.8.0
**Décisions couvertes** : P44-D-06a, P44-D-06b (labs désignés par Willy, AskUserQuestion session
principale, 2026-09-27).

## Procédure

Pour chacun des deux labs désignés (`~/jarvis-keystone`, `~/BusinessFlow-Lab`) :

1. **Empreinte AVANT** de l'arbre complet du lab (tout le dossier, `.git` compris), par un script
   Python (`os.walk(followlinks=False)`), une ligne triée par entrée : `d <chemin relatif>` pour
   un dossier, `f <chemin relatif> <sha256>` pour un fichier régulier, `l <chemin relatif> ->
   <cible>` pour un lien symbolique, `o <chemin relatif>` sinon. Écrite dans le dossier temporaire
   de la session (jamais dans le dépôt, jamais dans le lab).
2. **Passage en lecture seule** : `bash plugin/planning-core/scripts/recalc-planning.sh
   --planning=<lab>/.planning --read-only`, lancé et chronométré par un pilote Python
   (`time.perf_counter`), sortie JSON capturée dans le dossier temporaire de la session. Aucune
   commande `git` n'est lancée dans le lab, aucun `cd` vers lui : tous les chemins sont construits
   à l'exécution depuis `$HOME`.
3. **Empreinte APRÈS**, même script.
4. **`cmp`** des deux fichiers d'empreinte — l'écart attendu est vide. C'est la preuve EN SESSION,
   sur les fichiers d'empreinte bruts (non versionnés, hors du dépôt).
5. **Sha256 des deux fichiers d'empreinte** (pas des fichiers du lab eux-mêmes) — ce sont ces deux
   valeurs qui SURVIVENT dans ce rapport. Le verdict « aucune écriture » n'est jamais un jeton
   écrit à la main : il se relit en comparant `empreinte_avant` et `empreinte_apres` ci-dessous,
   qui doivent être strictement égaux.

Ni l'un ni l'autre lab n'a adhéré au nouveau schéma (`adhesion.declaree` mesurée à `"2.0"` dans
les deux cas, jamais `"cycles-v1"`) : seul le mode `--read-only` y tourne (P44-D-06b). Ces labs ne
sont pas rattachés aux « quatre retenus » de la spec §13, qui restent non nommés (P44-D-06c). Le
mode lecture seule ne lance jamais le détecteur GSD (qui, lui, appellerait `git`) — prouvé par R07
en 44-01 ; aucune commande `git` n'a été lancée par cette tâche dans l'un ou l'autre lab.

## Résultats

### `~/jarvis-keystone`

| Mesure | Valeur |
|---|---|
| Code de sortie | 0 |
| Durée | 0,126 s |
| Adhésion déclarée | `2.0` (non adhérent — socle existant, pas le modèle par cycles) |
| Unités (phases+plans) dérivées | 0 |
| Unités `indéterminé` | 0 |
| Cycles dérivés | 10 |
| Cycles `indéterminé` | 10 |
| Entrées hors modèle | 145 |
| `cmp` empreinte avant/après | identique (rc=0) |

Les 10 cycles ressortent tous `indéterminé` avec la raison `CYCLE.md-absent` : ce lab, comme prévu
par 44-CONTEXT.md § Specific Ideas, n'a ni `CYCLE.md`, ni `VERDICT.md`, ni `PLAN.md` avec le champ
de périmètre `ecrit:` — la dérivation s'arrête à la racine de chaque cycle sans descendre dans ses
phases, d'où `0` unité dérivée malgré une arborescence `.planning/` d'environ 2 000 (2 021
mesurés le 2026-09-28) fichiers. La mesure dit ce que le moteur fait d'un planning ancien, pas ce qu'il ferait d'un lab
au nouveau modèle — c'est son intérêt (comparaison à la spec, 9,7 à 12,4 s à 3 000 phases, à
l'ordre de grandeur seulement : structurellement non comparable ici, aucune phase n'étant
descendue).

### `~/BusinessFlow-Lab`

| Mesure | Valeur |
|---|---|
| Code de sortie | 0 |
| Durée | 0,066 s |
| Adhésion déclarée | `2.0` (non adhérent) |
| Unités (phases+plans) dérivées | 0 |
| Unités `indéterminé` | 0 |
| Cycles dérivés | 0 |
| Cycles `indéterminé` | 0 |
| Entrées hors modèle | 0 |
| `cmp` empreinte avant/après | identique (rc=0) |

Racine `.planning/` de 4 fichiers (`"phases_trace": false`), sans dossier `cycles/` : aucun cycle
à dériver, aucune entrée hors modèle (les quatre fichiers présents appartiennent tous au modèle —
`config.json`, `STATE.md`, etc., D-04).

## Lignes machine

```
PASSAGE-LAB lab=~/jarvis-keystone rc=0 duree_s=0.126 unites=0 indetermine=0 cycles_indetermines=10 hors_modele=145 empreinte_avant=e0b8c9610b9bccb35f70029f99d4b9ed9f44bf248c00b90b75964d12287cf47d empreinte_apres=e0b8c9610b9bccb35f70029f99d4b9ed9f44bf248c00b90b75964d12287cf47d
PASSAGE-LAB lab=~/BusinessFlow-Lab rc=0 duree_s=0.066 unites=0 indetermine=0 cycles_indetermines=0 hors_modele=0 empreinte_avant=6cac2146fa995879d207853a9d0ad8678f60e737a5f8275a23edbb9991a1bb89 empreinte_apres=6cac2146fa995879d207853a9d0ad8678f60e737a5f8275a23edbb9991a1bb89
```

Sur les deux lignes, `empreinte_avant` = `empreinte_apres` : aucun écart, aucune écriture. Les
fichiers d'empreinte et le JSON bruts (qui nomment des chemins d'autres dépôts) restent dans le
dossier temporaire de la session ; seuls les deux sha256 et les compteurs figurent ici.

---
*Phase : 44-moteur-modele-de-donnees-et-recalcul-d-etat-derive-du-disque*
*Plan : 05*
