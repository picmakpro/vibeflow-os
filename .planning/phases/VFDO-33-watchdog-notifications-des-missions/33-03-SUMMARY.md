---
phase: 33-watchdog-notifications-des-missions
plan: 03
type: summary
---

# 33-03 — Sous-contrôle stall/abandon dans check-guard-health.sh (WTCH-02, QUAL-01)

## Ce qui a été livré

`check-guard-health.sh` (déjà câblé sur `SessionStart`, générique tout le parc) gagne un second
sous-contrôle : il lit `driver-lock.sh status` (sibling résolu par répertoire de script, même
motif que `dag.sh`) et distingue trois verdicts — SAIN, STALL (`progress_age_seconds` au-delà du
seuil, heartbeat frais), ABANDON (`stale: true`, heartbeat mort). Le sous-contrôle
(`check_driver_stall()`) s'exécute **AVANT** les trois sorties précoces historiques liées à
l'existence/lisibilité de `HEALTH_DIR` — c'est le bug bloquant corrigé (D23) : placé après, il ne
tournait jamais sur une machine saine (répertoire absent = cas majoritaire) tout en restant vert
en test (fixtures `mkdir -p`).

Seuil `STALL_WINDOW` : 900s par défaut, strictement sous `VF_DRIVER_TTL` (1800s), configurable par
`--stall-window=` et `VF_STALL_WINDOW` (flag prioritaire sur la variable). Cascade Python
(`python3 → python → py -3`, rejet du stub Microsoft Store par chemin) et patron
`vf_guard_unavailable` (marqueur atomique tmp+mv + fallback `rm -f`) reproduits **localement**,
jamais en sourçant `vf-portable.sh`. Aucune nouvelle entrée `hooks.json`. QUAL-01 à quatre issues :
SAIN / SIGNAL / imparsable silencieux / dépendance indisponible bruyante (marqueur + stderr).

## Commits

Branche : `worktree-agent-aaf8aac7c9885d3b1` (base `feat/phase-33-watchdog-notifications`).

- `d78e3be` — `feat(33-03): sous-controle stall/abandon dans check-guard-health.sh (WTCH-02)`
- `2daf827` — `test(33-03): D14-D25 pour le sous-controle stall/abandon (QUAL-01, WTCH-02)`

## Comptage des tests — avant/après (mesuré sur disque)

| Suite | Avant (baseline mesurée) | Après |
|---|---|---|
| `test-check-guard-health.sh` | 32 PASS / 0 FAIL (D1-D13) | **75 PASS / 0 FAIL** (D1-D13 + D14-D25) |
| `test-driver-lock.sh` (non-régression, 33-01 inchangé) | 183 PASS / 0 FAIL | 183 PASS / 0 FAIL |
| `test-guard-driver-lock.sh` (non-régression) | — | 80 PASS / 0 FAIL |
| `test-vf-portable.sh` (T12 doit rester à 5 consommateurs) | — | 16 ok / 0 ko / 0 skip, `git diff --stat` **vide** |
| Découverte `find plugin scripts -type f -path '*/tests/test-*.sh' \| wc -l` | — | **65** (inchangé, ce plan n'ajoute aucune suite) |

D1-D13 (historiques) restent verts sans aucune modification de leur code.

**Note de base (signalée, pas une régression de ce plan)** : `test-dag.sh` rend 99 PASS/0 FAIL
dans ce worktree, contre 123 PASS annoncés par le manager pour le dépôt principal — mon worktree
a été forké **avant** l'intégration de 33-02/33-04 en amont ; `dag.sh`/`test-dag.sh` ne font partie
d'aucun commit de ce plan (périmètre strict : `check-guard-health.sh` +
`test-check-guard-health.sh` uniquement).

## Contrôles positifs consignés

- **D18** (rétrocompat) : avant d'invoquer le script sous test, lecture directe du `meta` confirme
  l'absence de la ligne `progress_epoch=` — assertion dédiée « contrôle positif », verte.
- **D20** (aucun interprète Python) : avant d'invoquer la copie isolée, `command -v python3` /
  `python` / `py` échouent tous les trois dans le PATH restreint — assertion dédiée, verte.

## Mutations rouges (3 exigées) — preuves race-free

Le worktree partage le système de fichiers avec un autre agent gsd-executor toujours actif sur ce
même plan (dispatché en tâche de fond plus tôt dans la session) : plusieurs tentatives de
mutation directement sur le fichier partagé `plugin/conductor/scripts/check-guard-health.sh` ont
été polluées par des écritures concurrentes (constaté par `git diff` changeant entre deux lectures
consécutives sans action de ma part). Pour obtenir une preuve fiable, chaque mutation a été
rejouée sur une **copie isolée dans `/tmp`** (`git show HEAD:...` figé + `driver-lock.sh` copié en
sibling), avec `VF_DRIVER_LOCK` pointant systématiquement sous un répertoire `/tmp` dédié — jamais
le vrai `.planning/DRIVER.lock` du dépôt. Le fichier partagé, lui, a été laissé identique à HEAD
tout du long (`git diff --stat` vide confirmé après coup) : ces mutations sont des preuves
ponctuelles, jamais committées.

### Mutation n°1 — `stale == "true"` neutralisé (doit casser D17/abandon)
Remplacement de `if [ "$d_stale" = "true" ]; then` par
`if [ "MUTATION1-TOUJOURS-FAUX" = "jamais-vrai" ]; then` dans `check_driver_stall()`.

Fixture : lock acquis, `heartbeat_epoch` antidaté de 2094s (> TTL 1800s, `stale` doit être `true`).

- **Attendu (baseline, copie non mutée)** : `rc=0`, ligne
  `[mission-watchdog] abandon detecte — owner=d17-owner step=d17-step (...)`.
- **Obtenu (baseline)** : `rc=0`, ligne d'abandon présente — confirmé.
- **Attendu (mutée)** : abandon non détecté → repli sur SAIN (aucun `progress_epoch` backdaté dans
  cette fixture, donc pas de stall non plus).
- **Obtenu (mutée)** : `rc=3`, `[check-guard-health] SAIN — aucun repertoire de sante (... absent).`
  — l'abandon n'est **plus jamais** signalé. Rougit comme prévu.
- Restauration : `git checkout --` sur le fichier partagé (déjà identique à HEAD, confirmé par
  `git diff --stat` vide avant/après).

### Mutation n°2 — retrait de `report_self_unavailable`/`STALL_INDETERMINATE=1` (doit casser D19)
Dans `check_driver_stall()`, le bloc `driver-lock.sh introuvable` perd son appel à
`report_self_unavailable` et son `STALL_INDETERMINATE=1`, ne conservant que `return 0`.

Fixture : copie isolée de `check-guard-health.sh` dans un répertoire **sans** `driver-lock.sh`
sibling (D19).

- **Attendu (baseline)** : `rc=4` (INDÉTERMINÉ), marqueur `check-guard-health.sh.marker` écrit,
  message sur stderr.
- **Obtenu (baseline)** : `rc=4`, stderr =
  `[check-guard-health] driver-lock.sh introuvable ou non executable (...)` puis
  `INDETERMINE, rien n'a ete verifie : ...`, marqueur présent (`ls` confirmé).
- **Attendu (mutée)** : dégradation en vert de complaisance — plus de marqueur, plus de stderr,
  `rc=3` (SAIN) au lieu de `4`.
- **Obtenu (mutée)** : `rc=3`, stdout =
  `[check-guard-health] SAIN — aucun repertoire de sante (... absent).`, **aucun** marqueur écrit
  (répertoire de santé jamais créé). Exactement le vert de complaisance que QUAL-01 interdit —
  rougit comme prévu.
- Restauration : fichier partagé jamais touché pour cette mutation (travaillée entièrement sur
  copie `/tmp`).

### Mutation n°3 — bug d'ordonnancement reproduit (doit casser D23)
Les trois sorties précoces (répertoire absent/pas un répertoire/non listable) reviennent **avant**
l'appel à `check_driver_stall`, qui ne s'exécute alors plus que si `HEALTH_DIR` existe déjà.

Fixture : lock acquis, `progress_epoch` antidaté de 1160s (> seuil 900s défaut, `heartbeat_epoch`
frais → stall pur), `HEALTH_DIR` jamais créé avant l'appel (D23).

- **Attendu (baseline)** : `rc=0`, ligne
  `[mission-watchdog] stall detecte — owner=d23-owner step=d23-step (progres fige depuis 1166s, ...)`,
  et `HEALTH_DIR` reste **absent** après l'appel.
- **Obtenu (baseline)** : `rc=0`, ligne de stall présente, `ls` sur `HEALTH_DIR` confirme
  l'absence après coup — confirmé.
- **Attendu (mutée)** : le sous-contrôle ne tourne jamais (répertoire absent → sortie précoce
  immédiate, `check_driver_stall` jamais appelée) → stall **non signalé**, `rc=3`.
- **Obtenu (mutée)** : `rc=3`,
  `[check-guard-health] SAIN — aucun repertoire de sante (... absent).` — le stall réel disparaît
  entièrement du verdict. Rougit comme prévu, reproduit exactement le défaut du 2ᵉ plancheck
  externe.
- Restauration : fichier partagé jamais touché pour cette mutation (travaillée entièrement sur
  copie `/tmp`).

## D25 — preuve de protocole RÉEL (S1 option b), trace obligatoire

Fixture : `driver-lock.sh acquire --owner=tester` (isolé sous `$WORK_DIR`, jamais le vrai
`.planning/DRIVER.lock`) puis boucle **bornée** de 3 itérations `sleep 1 && driver-lock.sh
heartbeat --owner=tester` — **jamais** `mark-progress`, **jamais** de forgeage/`sed` sur le `meta`.

- **Durée réelle mesurée de la boucle** : 3s (mesures répétées, toujours ≤ 5s — borne du plan
  respectée).
- **Preuve que `progress_epoch=` n'a pas changé** : capture de la ligne complète
  `progress_epoch=<valeur>` dans le `meta` juste après `acquire` et juste après la boucle de
  heartbeats — **valeur strictement identique** dans chaque run (ex. mesuré :
  `progress_epoch=1786967282` avant et après). `grep -c '^progress_epoch=' meta` == `1` avant ET
  après (ligne unique, ni dupliquée ni retirée).
- **Verdict constaté** : `VF_STALL_WINDOW=1` (seuil abaissé pour rendre l'attente courte),
  invocation du script sous test → `rc=0`, ligne
  `[mission-watchdog] stall detecte — owner=tester step=d25-step (...)`, **jamais** de ligne
  `abandon` (stale reste faux, très en dessous du TTL 1800s).
- Cette exception au `sleep` est documentée **dans le test lui-même** (commentaire en tête du bloc
  D25) comme exception explicite à la prohibition « aucun sleep non borné », qui ne couvre que les
  tests de cadence arbitraires — jamais généralisée aux autres cas (D14-D24 restent tous forgés).

Reproduit de façon stable sur plusieurs exécutions (~3s, jamais > 5s observé).

## Vérification finale (dernière mesure sur disque, `git status` propre)

```
bash -n plugin/conductor/scripts/check-guard-health.sh      → 0
test-check-guard-health.sh                                   → 75 PASS / 0 FAIL
test-driver-lock.sh                                           → 183 PASS / 0 FAIL
test-guard-driver-lock.sh                                      → 80 PASS / 0 FAIL
test-vf-portable.sh                                            → 16 ok / 0 ko / 0 skip
git diff --stat plugin/_internal/tests/test-vf-portable.sh    → (vide)
find .../tests/test-*.sh | wc -l                                → 65
```

Critères de comptage de lignes (2ᵉ plancheck externe, C5 corrigé) — bornés aux lignes de code de
`report_self_unavailable()` :

- `touch` (code, hors commentaires) : `0`
- `mv` (code, hors commentaires) : exactement `1`
- `rm` (code, hors commentaires) : exactement `1`, localisé **dans** `report_self_unavailable()`
  (`sed -n '/^report_self_unavailable()/,/^}/p' | grep -v '^[[:space:]]*#' | grep -c 'rm -f'` = `1`)
- `source .../vf-portable` : `0` occurrence (le nom `vf-portable` reste légitimement présent 3 fois
  en commentaire de documentation du couplage)
- littéral `eval` : `0` occurrence

## Zones non prouvées / déviations

Aucune déviation de portée. Une seule adaptation méthodologique, documentée ci-dessus : les preuves
de mutation ont été obtenues sur des copies isolées en `/tmp` plutôt que directement sur le fichier
du dépôt, à cause d'un autre agent gsd-executor actif en tâche de fond sur ce même plan dans ce
même worktree (écritures concurrentes constatées à plusieurs reprises). Le fichier livré dans les
deux commits reste, lui, strictement celui écrit par ce worker — vérifié `git diff --stat` vide
contre HEAD avant la rédaction de ce SUMMARY.

**Ordre TDD (`tdd="true"`) non observé au caractère près** : la tâche 1 de ce plan est un tracer
`tdd="true"`, qui prescrit un commit RED (tests committés en échec) strictement AVANT le commit
GREEN (implémentation). L'ordre effectif des deux commits livrés est `d78e3be` (feat/GREEN) PUIS
`2daf827` (test) — la collision d'agents documentée ci-dessus (deux workers gsd-executor actifs sur
le même plan, dans le même worktree) explique la divergence : le worker dont l'implémentation a
atterri en premier sur le disque partagé a été committée avant que les tests D14-D25 correspondants
ne le soient par l'un ou l'autre worker. Aucune réécriture d'historique n'a été tentée pour corriger
cet ordre après coup (interdit par le protocole — jamais d'amend, jamais de commit destructif). En
compensation, chaque cas D14-D25 a été vérifié manuellement un par un contre le comportement réel du
script AVANT la rédaction finale de la suite, et les trois mutations rouges exigées par le plan
apportent la preuve de discriminance (un test qui ne peut jamais rougir sous mutation ciblée est le
même défaut qu'un RED qui ne s'est jamais produit) — une rigueur équivalente en substance, mais pas
au sens littéral de la séquence de commits prescrite par `tdd="true"`.
