# Plancheck EXTERNE des plans 33-01..33-05 — verdict consolidé

> Trois vérificateurs FRAIS dispatchés en direct le 2026-08-17, sur trois angles disjoints
> (goal-backward · confrontation au disque et facture · cohérence inter-plans et vagues).
> Aucun n'avait participé à la rédaction. **Verdicts : 6, 10 et 7 bloquants.**
>
> Le plan-checker interne n'avait rien remonté. **Troisième phase consécutive** où l'écart
> interne/externe est de cet ordre (Phase 31 : 0 → 9 ; Phase 32 : 0 → 9 ; ici : 0 → ~14 distincts).
> Cette étape n'est pas une formalité : deux défauts ci-dessous ont été **reproduits par
> exécution** et auraient tourné **vert de bout en bout**.

## Bloquants convergents — trouvés indépendamment par plusieurs vérificateurs

### C1 — `mark-progress` EFFACE le champ `step` du meta *(33-01 ; reproduit 2×)*
`rewrite_meta()` réémet `$STEP`, la **globale** issue du parsing d'arguments, jamais la valeur du
fichier — c'est pourquoi `heartbeat` porte la garde `[ -z "$STEP" ] && STEP="$(meta_get step)"`
(L502). L'étape 6 de 33-01 l'omet, et 33-02 appelle `mark-progress` à **chaque** transition de
nœud : dès le premier nœud, l'étape pilotée disparaît du lock.
Trace : `step=etape-42-refonte` → `step=` après un seul appel.
Consommateurs qui perdent l'information : `check-branch-claim.sh:111`, `guard-driver-lock.sh:422`,
et la ligne de stall de 33-03 (qui affichera toujours `step=`).
**Aucun cas de test ne l'assert** → la facture serait verte sur le code cassé.
C'est la mutation rouge de la Phase 32 rejouée à l'identique, sur `step` au lieu de `session_ids`.

### C2 — Le sous-contrôle de stall est INATTEIGNABLE dans le cas nominal *(33-03 ; reproduit 2×)*
33-03 place l'appel dans le bloc de verdict final (L175-184). Or `check-guard-health.sh` sort
**avant** dans trois cas : répertoire absent → `hook_exit 3` (L103), pas un répertoire → 4,
non listable → 4.
Le répertoire de santé n'existe **que si un garde du parc est déjà tombé en panne**. Sur une
machine saine — le cas majoritaire, y compris celle-ci (`~/.cache/vibeflow/guard-health` absent) —
le script sort SAIN et `check_driver_stall` **ne tourne jamais**. WTCH-02 mort en production.
Et **vert en test** : les fixtures font `mkdir -p`, donc les cas D-* atteignent la ligne 175.
Garde aveugle avec tous les cas verts — exactement ce que QUAL-01 interdit.

### C3 — Numérotation T26-T33 déjà prise *(33-01 ; mesuré 2×)*
`test-driver-lock.sh` porte **T0 à T50, 151 assertions**, pas « 25 cas historiques (T1-T25) ».
Les huit numéros que le plan veut poser existent déjà → le critère « affiche les blocs `=== T26` à
`=== T33` » est **vert avant d'écrire une ligne**, et la suite gagne deux `=== T28` de sémantiques
opposées. → renuméroter en **T51-T58**.

### C4 — `grep -c 'vf-portable' check-guard-health.sh` rend **3**, pas 0 *(33-03 ; mesuré 2×)*
Le bloc `<automated>` du plan est **rouge sur le fichier non modifié**. Pour le verdir, l'exécutant
devrait supprimer les lignes 27-32 — c'est-à-dire la documentation du **couplage critique**
écrivain/lecteur que `33-TERRAIN.md` déclare intouchable. → assertion d'absence de `source`.

### C5 — Critères `rm`/`mv`/`touch` auto-contradictoires *(33-03 ; 3×)*
Le plan impose une écriture atomique `tmp + mv -f` **et** exige `grep -c '\brm \|\bmv \|\btouch '`
== `0`, en renvoyant l'exclusion « à l'œil ». `grep -c` ne sait pas exclure : 0 aujourd'hui, ≥ 1
après. Contredit aussi l'invariant d'en-tête « ce script n'écrit RIEN, nulle part » (L110), que le
plan ne prévoit pas d'amender.

### C6 — `run_bounded` tue à **5 s**, présenté comme 10 s *(33-02 T38, 33-05 T44 ; reproduit)*
`test-dag.sh` : `( sleep 5; kill -9 "$pid" )`. Avec le `timeout=5` prescrit côté Python, le process
est tué **avant** `save(dag)` : `rc=137`, et le DAG reste `"status": "ready"` — **la transition est
perdue**. Les trois assertions de T38 échouent.
Aggravé par le placement : les deux plans appellent la notification **AVANT** `save(dag)`, alors
que `33-TERRAIN.md` avertit que `save()` est une **réécriture non atomique**. → appeler **après**.

### C7 — T40/T41 déclenchent de VRAIS toasts *(33-05 ; contredit un invariant dur de 33-04)*
33-05 copie et instrumente le **vrai** `notify.sh` sans `VF_NOTIFY_FORCE_CHANNEL`, sans
`VF_NOTIFY_BIN_DIR`, sans PATH assaini. Sur macOS la cascade trouve `osascript` → deux
notifications système à chaque `bash test-dag.sh` ; en CI Linux, `notify-send` s'il est présent.
33-04 a construit trois points d'injection exactement pour l'éviter ; 33-05 n'en utilise aucun.

### C8 — « halt condition » : la prémisse de 33-05 est fausse *(3×)*
33-05 ferme le cas sur « `blocked` n'est jamais écrit par `mark` ». Or `dag.sh:70`
`VALID = {"blocked","ready","running","done","failed"}` et L246 écrit le statut directement :
`mark --status=blocked` est valide. Et `mission-flow.md:245`, la source que 33-05 cite, dit du halt
autonome « le laisser **`blocked`/`failed`** ». La conclusion reste juste par accident, la
justification est fausse — et le critère n°3 nomme « halt condition » explicitement.

## Bloquants STRUCTURELS — remontés à l'humain, pas corrigeables par un worker

### S1 — Le verdict STALL est inatteignable en production
`STALL_WINDOW` (33-03) = **1800 s** = `VF_DRIVER_TTL` (`driver-lock.sh:40`). Et le heartbeat de
vivacité est émis par le manager « **entre les étapes** » (`mission-flow.md:51-55`), c'est-à-dire
**au même tour** que le `dag.sh mark` qui écrira le progrès. Conséquences mesurées :
- mission gelée → les **deux** horloges gèlent → à 1800 s le lock devient `stale` → 33-03 lit
  `stale` d'abord → verdict **ABANDON**, jamais STALL ;
- mission vivante → les deux horloges avancent ensemble → **jamais de divergence**.
La branche « vivant mais bouclant » n'est donc atteignable **que sur epochs forgés** (cas de test).
Le critère de succès n°2 serait *prouvé par test et faux en usage réel*.
> C'est la prémisse de **D-33-A** elle-même qui est en cause : deux horloges ne se séparent que si
> elles ont deux sources. Ici elles ont le même émetteur, au même instant.

### S2 — Le goal amendé promet « au prochain GESTE », les plans ne livrent que « à la prochaine OUVERTURE de session »
D-33-B nommait deux points de détection : le hook `SessionStart` **et** « un point de contrôle sur
les gestes de DAG ». Le second n'est implémenté par **aucune tâche** : 33-02 et 33-05 *écrivent* au
point `mark`, aucune ne *lit* ni ne *signale*. La seule lecture est câblée sur `SessionStart`
matcher `startup` — au démarrage d'une session, pas à un geste d'une session déjà vivante. Une
session ouverte 8 h qui pilote une mission bouclée ne verra jamais le signal.

## Findings notables (non bloquants, à absorber dans la passe de correction)
- **Critères non falsifiables** : `grep -c … rend au moins 0` (33-01) — un `grep -c` rend toujours
  ≥ 0, aucune commande ne peut le contredire. Idem `grep -qc` (contradictoire, `-q` l'emporte),
  et `record_progress(driver_lock_sh)` == 1 alors que le motif capture aussi la ligne `def` (→ 2).
- **Garde anti-vert-à-vide absente** de `test-dag.sh`, `test-driver-lock.sh`,
  `test-vf-portable.sh` — et aucun plan ne l'ajoute (seule la suite neuve de 33-04 la porte).
- **33-03 réintroduit `command -v python3` en dur** alors qu'il cite `vf_resolve_python` comme
  patron : perd la cascade `python3 → python → py -3` **et** le rejet du stub Microsoft Store —
  la régression que la Phase 30 avait fermée, rouverte sur un script de hook du parc entier.
- **33-04 N8 est vert sur code sain ET vert sous mutation** : il mesure le retour du process, pas
  la libération du **pipe** ; or l'appelant réel capture la sortie et attend l'EOF — mesuré 4,37 s
  de blocage sur la variante « détachement de façade », que N8 déclare bonne.
- **33-03 : `STALL_INDETERMINATE`/`STALL_LINE` jamais initialisés** sous `set -u` → `unbound
  variable` sur le chemin sain. Et le sous-contrôle indisponible **masque** tout le reporting de
  marqueurs existant (sortie 4 avant la ligne `FRESH_COUNT`).
- **33-03 : seuil non configurable en production** — l'entrée `hooks.json` passe `--hook` seul,
  donc `--stall-window=` est inatteignable → prévoir `VF_STALL_WINDOW`.
- **33-02 : la 4ᵉ issue manque là où elle mord** — si `mark-progress` échoue durablement,
  `progress_epoch` gèle sur une mission saine → **faux stall**, en silence.
- **Collision d'IDs de menace** `T-33-05..T-33-10` entre 33-02/03/04/05 (écriture parallèle).
- **Aucun plan ne touche** `CHANGELOG.md`, `VERSION`, `mission-flow.md`, `vf-dev-manager.md` : le
  verbe `mark-progress` et `notify.sh` n'existeraient dans **aucune doctrine lue par les managers**.
- `33-TERRAIN.md` annonce `check-guard-health.sh (185 l.)` ; `wc -l` en rend **184**.

## Ce qui TIENT (vérifié par commande, pas supposé)
- **L'additivité de `progress_epoch`** : même `meta`, même `rewrite_meta()`, patron du 3ᵉ
  positionnel correct ; `lock_age()`/`stale`/TTL non touchés. Aucun second fichier, aucun second
  script. WTCH-01 est respecté sur ce point.
- **Jamais tuer** : aucun `takeover`/`release`/`kill`/`rm` dans les 5 plans ; détection par
  ABSENCE, jamais auto-déclarée. ADR-031 tenu.
- **Jamais à chaque tour** : `record_milestone()` filtre sur `done|failed`, et **T42 est un cas de
  discriminance nommé « ne JAMAIS retirer »** prouvant qu'un `running` ne notifie pas.
- **La couture d'interface `notify.sh` entre 33-04 et 33-05 est SAINE** — nom, chemin, ordre et
  nombre d'arguments, code de sortie : aucune divergence, malgré l'écriture en parallèle.
  Le risque assumé par 33-05 ne s'est pas matérialisé.
- **La couture producteur→lecteur `progress_epoch`** : noms de champs, unités et formes JSON
  identiques d'un plan à l'autre. Le détecteur ne sera pas aveugle par écart de nommage.
- **Aucun plan ne câble sur l'hypothèse de hooks non prouvée** : 33-03 étend un script **déjà
  armé** sur `SessionStart`, 33-05 appelle `notify.sh` en sous-processus. **Zéro entrée
  `hooks.json` neuve** → le bug d'idempotence cross-matcher n'est jamais approché.
- **Portabilité GNU/BSD non régressée** : aucun plan n'introduit ni ne ré-inverse `stat`/`sed -i`.
- **Numéros de ligne** cités par les plans : exacts dans leur immense majorité.

## Vagues d'exécution — sûres, sous deux conditions non écrites dans les plans
| Vague | Plans | Condition |
|---|---|---|
| 1 | `33-01` ∥ `33-04` | périmètres d'écriture ET de mesure strictement disjoints (vérifié) |
| 2 | `33-02` ∥ `33-03` | **barrière : 33-01 ET 33-04 commités** (sinon la mesure de 33-03 sur `test-vf-portable.sh` casse) |
| 3 | `33-05` seul | — |

Deux arêtes de dépendance manquent aux frontmatters : `33-03` dépend aussi de **33-04** (il mesure
un fichier que 33-04 modifie — *piège du périmètre de mesure*), et `33-05` dépend aussi de
**33-03** (il exécute sa suite). À déclarer pour que le dispatcher ne puisse pas les violer.
Enfin, au sein d'une vague, le protocole de mutation rouge (`commit → mutation → git checkout --`)
partage l'index git : **un worktree par plan**, ou séquencement strict au moment des mutations.
