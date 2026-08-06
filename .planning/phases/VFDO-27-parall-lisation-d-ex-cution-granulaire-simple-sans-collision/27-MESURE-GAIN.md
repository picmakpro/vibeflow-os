# Phase 27 — Mesure du gain réel (PAEX-07)

**Établi le :** 2026-08-06 · **Par :** `gsd-executor` (plan 27-04, mandat plan seul)
**Origine :** D-10 (« la mesure est un livrable, pas une promesse ») et D-13 (« tout chiffre gravé
porte sa méthode et se re-dérive »), tranchés dans `27-CONTEXT.md` / `27-RESEARCH.md` §Livrable 5.

> ## STATUT DE CE DOCUMENT
>
> **Trois blocs, trois statuts distincts — ne jamais les fusionner.**
>
> | Bloc | Statut |
> |---|---|
> | 1. Plafond d'étages (Phase 24) | **acquis, rétroactif, qualitatif** — re-dérivé ici, pas remesuré |
> | 2. Baseline d'horloge inline (Phase 27, vague 1) | **mesuré par ce plan (27-04), avant toute activation de `claude_orchestration`** |
> | 3. Mesure après activation | **vide à ce stade** — structure posée, remplissage réservé au plan `27-06` |
>
> Ce document est écrit **pendant que `.planning/config.json` ne porte encore aucune clé
> `claude_orchestration`** — précondition vérifiée sur pièce juste avant l'écriture de ce bloc (voir
> Bloc 2, commande de contrôle). C'est ce qui rend le Bloc 2 une baseline et non une mesure détruite.

---

## Bloc 1 — Plafond d'étages de la Phase 24 (acquis, rétroactif, qualitatif)

Re-dérivation de la table publiée dans `.planning/ROADMAP.md` §Phase 27 « Le chiffre qui devrait
décider la phase », elle-même issue de l'application du partitionneur amont (`partitionStages`) aux
12 plans réels de la Phase 24 :

| Vague | Plans | Étages après partition | Paires en collision de fichier |
|---|---|---|---|
| 1 | 5 | 1 | **0** |
| 2 | 4 | 1 | **0** |
| 3 | 2 | 1 | **0** |
| 4 | 1 | 1 | 0 |

**12 exécutions sérielles → 4 étages, soit un plafond de 3,00×, et zéro collision de fichier sur les
quatre vagues.**

**C'est une compression d'étages, pas un gain d'horloge — la distinction est à tenir dans toute
cette phase.** Un plafond d'étages dit combien de tours de dispatch séquentiel un manager économise
*s'il* dispatche chaque étage en un seul message ; il ne dit strictement rien sur le temps d'horloge
réellement gagné, qui dépend de la durée de chaque plan à l'intérieur d'un étage (dominée par le plus
long) et du mécanisme de dispatch effectivement utilisé.

**Ce que ce corpus ne permet PAS d'établir — écrit ici, pas en note de bas de page.** Les durées
d'horloge par plan de la Phase 24 ne sont pas disponibles dans `.planning/STATE.md` : la table
`Per-Plan Metrics` de ce fichier est clairsemée (au moment de l'écriture, elle ne porte que deux
entrées exploitables, `Phase VFDO-19 P02` et `Phase 20 P07` — aucune des 12 plans de la Phase 24 n'y
figure). **Aucune mesure d'horloge rétroactive complète n'est donc possible sur ce corpus.** Le
Bloc 1 reste, par construction, une donnée qualitative de compression d'étages — jamais un gain de
temps chiffré.

---

## Bloc 2 — Baseline d'horloge inline de la Phase 27, vague 1 (mesurée ici)

### Précondition tenue — vérifiée avant toute mesure

```bash
grep -c "claude_orchestration" .planning/config.json
```

Sortie au moment de la capture : **0 occurrence**. La capability n'est ni activée ni configurée ; le
dispatch de la vague 1 mesurée ci-dessous a eu lieu et est documenté **entièrement avant** toute
activation possible de `claude_orchestration` sur ce dépôt.

### Corpus mesuré

La vague 1 de cette même phase (27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision) :
trois plans à `files_modified` disjoints, dispatchés en parallèle par l'orchestrateur de phase —
`27-01` (dag.sh / stages), `27-02` (doctrine team-kernel.md), `27-03` (armement `isolation:
worktree`). C'est le **seul niveau où le parallélisme a effectivement lieu** aujourd'hui : un
exécuteur de plan est lui-même un sous-agent, il ne peut pas mesurer honnêtement un dispatch
parallèle depuis sa propre position (`shouldFlattenDispatch()` aplatit ce qu'il lancerait) — la
mesure remonte donc au niveau des commits d'orchestrateur.

### Commande exacte ayant produit les horodatages

```bash
git log --all --pretty=format:'%H|%ad|%s' --date=iso-strict --extended-regexp \
  --grep='^[a-z]+\(27-01\)' | sort -t'|' -k2
git log --all --pretty=format:'%H|%ad|%s' --date=iso-strict --extended-regexp \
  --grep='^[a-z]+\(27-02\)' | sort -t'|' -k2
git log --all --pretty=format:'%H|%ad|%s' --date=iso-strict --extended-regexp \
  --grep='^[a-z]+\(27-03\)' | sort -t'|' -k2
```

Le motif ancre le tag de plan **en tête du sujet du commit** (`^[a-z]+\(27-0N\)`) — un `--grep`
non ancré capture aussi des commits de doctrine/planning qui *mentionnent* le plan sans en être un
commit de tâche (vérifié : `--grep='(27-01)'` sans ancre remonte des faux positifs comme
`docs(27): ...` ou `planning(27): ...`). L'ancrage élimine ce bruit.

### Commits retenus

| Hash court | Horodatage (ISO, auteur) | Plan | Sujet |
|---|---|---|---|
| `8b37b69` | 2026-08-05T23:39:51+02:00 | 27-01 | feat(27-01): dag.sh calcule stages via partitionStages() amont |
| `c776b59` | 2026-08-05T23:48:26+02:00 | 27-01 | test(27-01): T25-T30 — couverture stages (recouvrement, disjonction, repli) |
| `5728d66` | 2026-08-05T23:49:47+02:00 | 27-01 | docs(27-01): mission-flow.md documente stages, sa garantie et son repli |
| `509f56e` | 2026-08-05T23:53:48+02:00 | 27-01 | docs(27-01): complete plan (SUMMARY) |
| `d708b72` | 2026-08-05T23:42:39+02:00 | 27-02 | docs(27-02): ROADMAP — remplace l'avertissement de comptage par le résultat re-dérivé |
| `69e1cb1` | 2026-08-05T23:48:40+02:00 | 27-02 | docs(27-02): complete doctrine-fix plan (SUMMARY) |
| `02138e5` | 2026-08-05T23:25:48+02:00 | 27-03 | planning(27-03): assertion machine sur baseRef avant armement d'isolation |
| `1ec1f63` | 2026-08-05T23:34:12+02:00 | 27-03 | chore(27-03): pose .worktreeinclude et tranche le statut de .claude/worktrees/ |
| `da8ad8a` | 2026-08-05T23:39:01+02:00 | 27-03 | docs(27-03): écrit la portée de l'isolation worktree (groupe B, baseRef, hypothèses) |
| `807db3d` | 2026-08-05T23:59:31+02:00 | 27-03 | docs(27-03): ajoute la preuve empirique de fuite de commit (Partie 4) |
| `0e80db9` | 2026-08-06T03:47:44+02:00 | 27-03 | fix(27-03): arme isolation: worktree sur les 13 agents ecrivains non-managers |
| `183bff7` | 2026-08-06T03:49:42+02:00 | 27-03 | docs(27-03): SUMMARY — cloture du plan, histoire non lineaire consignee |

### Écart par plan (premier commit → dernier commit du même plan)

| Plan | Premier | Dernier | Écart | Continuité |
|---|---|---|---|---|
| 27-01 | `8b37b69` 23:39:51 | `509f56e` 23:53:48 | **13min57s** | une seule session continue |
| 27-02 | `d708b72` 23:42:39 | `69e1cb1` 23:48:40 | **6min01s** | une seule session continue |
| 27-03 | `02138e5` 23:25:48 (05/08) | `183bff7` 03:49:42 (06/08) | **4h23min54s** | **deux sessions distinctes — voir découverte ci-dessous** |

### Écart de la vague — deux lectures, jamais à fusionner en un seul chiffre

**(a) Fenêtre de dispatch initial continu**, du premier commit de n'importe lequel des trois plans
au dernier commit produit avant toute interruption : `02138e5` (23:25:48) → `807db3d` (23:59:31) =
**33min43s**. Cette fenêtre couvre l'intégralité de 27-01 et 27-02 (clos) mais **pas** la clôture de
27-03 : à `807db3d`, 27-03 a produit 4 de ses 6 commits, son `SUMMARY.md` n'existe pas encore.

**(b) Écart littéral premier commit → dernier commit, toutes sessions confondues** : `02138e5`
(23:25:48, 05/08) → `183bff7` (03:49:42, 06/08) = **4h23min54s**. Ce chiffre est dominé à plus de
90 % par un intervalle sans aucun commit sur les trois plans (23:59:31 → 03:47:44, soit ~3h48) —
**pas** par du dispatch actif. Le citer seul, sans cette note, serait une promesse de performance
mensongère (c'est exactement le risque T-27-04-02/T-27-04-03 du plan).

### Découverte non anticipée par le plan — cinquième limite propre à ce corpus

Le plan `27-04-PLAN.md` énumère quatre limites à écrire (borne de fin et non durée d'agent, tailles
hétérogènes, échantillon unique, impossibilité pour un sous-agent de mesurer honnêtement un dispatch
parallèle). L'exécution de cette mesure en révèle une **cinquième, propre à ce corpus précis et non
prévisible avant de lire les commits réels** : la vague 1 de la Phase 27 n'a **pas** été un dispatch
parallèle continu de bout en bout pour les trois plans. Le plan `27-03` s'est arrêté à mi-parcours
(après 4 commits, sans `SUMMARY.md`) et n'a repris que ~3h48 plus tard, dans une session distincte —
documentée dans `.planning/STATE.md` §Decisions comme une **pause d'arbitrage humain** (« 2026-08-06
— Phase 27, reprise sur arbitrage : les trois gels sont levés »). Cette pause n'est ni un temps
d'agent ni un temps de dispatch : c'est un temps d'attente d'une décision humaine, hors du périmètre
que cette baseline cherche à caractériser. **Toute réutilisation future de ce même échantillon de
vague 1 comme référence doit filtrer explicitement cette pause**, faute de quoi l'écart de la vague
se confondrait avec un temps d'attente humain plutôt qu'avec un temps de dispatch.

### Les quatre limites prévues par le plan, écrites ici en toutes lettres

1. **Borne de fin, jamais durée d'agent.** Un horodatage de commit marque la fin (le moment où le
   travail est matérialisé en git), jamais le démarrage de l'agent qui l'a produit. L'écart mesuré
   ci-dessus est donc une **borne inférieure du dispatch observable**, pas une durée d'agent réelle
   — le temps de lecture/recherche entre le lancement de l'agent et son premier commit n'est jamais
   compté.
2. **Tailles hétérogènes.** Les trois plans de la vague 1 sont de volumes très différents (27-02 : 2
   commits, 6 min ; 27-01 : 4 commits, 14 min ; 27-03 : 6 commits sur deux sessions). Tout écart de
   vague est **dominé par le plus long**, jamais représentatif d'un plan « moyen ».
3. **Échantillon unique.** C'est **une seule vague, une seule mesure**. Aucune garantie de stabilité
   inter-run n'existe dans la recherche source (`27-RESEARCH.md`) — sujet neuf, aucune donnée
   historique de ce type dans ce dépôt avant cette phase.
4. **Un exécuteur de plan ne peut pas mesurer honnêtement un dispatch parallèle depuis sa propre
   position.** `shouldFlattenDispatch()` aplatirait tout sous-dispatch qu'un exécuteur tenterait de
   lancer lui-même — c'est précisément pourquoi cette mesure remonte au niveau des commits
   d'orchestrateur (git log sur les tags de plan) plutôt qu'à une mesure interne à un agent.

### Portée du Bloc 2 — ce qu'il alimente et ce qu'il n'alimente PAS

**Cette baseline n'alimente pas le rapport avant/après du Bloc 3.** Elle porte sur un corpus **réel**
(les trois plans de la vague 1 de cette phase), tandis que le Bloc 3 portera sur le **corpus jouet
étalon** `27-mesure/waves-toy.json` (posé par la Tâche 1 de ce même plan, prouvé parallélisable :
`emit-workflow --run-id mesure-27-baseline` rend `summary.plans == 2` et `stagesByWave[0]` un seul
étage de deux plans). Aucun étalon commun ne relie les deux corpus — le ratio avant/après contrôlé de
cette phase se joue **entièrement à l'intérieur du Bloc 3**, des deux côtés, sur le même manifeste,
avec un identifiant de run fixe et au moins deux répétitions par côté pour amortir la variance
(protocole détaillé au Bloc 3). Le Bloc 2 reste une **donnée de contexte réelle et utile en
elle-même** — l'échelle de grandeur du dispatch inline d'aujourd'hui — jamais fusionnée avec la
mesure contrôlée du Bloc 3 faute d'étalon partagé.

---

## Bloc 3 — Mesure après activation

STATUT-BLOC-3: NON-MESURABLE

**Statut : rempli par ce plan (`27-06`), issue de non-mesurabilité.** Le plan `27-05` a rendu son
verdict — refus motivé de l'activation de `claude_orchestration` — sur le checkpoint de sa tâche 2,
conduit en session principale le 2026-08-06. Conformément à la branche « refus » du how-to-verify
de la Tâche 1 de ce plan, l'A/B n'a **pas eu lieu** : ni côté inline, ni côté workflow, sur
`27-mesure/waves-toy.json`. Ce bloc consigne le motif et le déclencheur de reprise, tels qu'écrits
dans `27-DECISION-claude-orchestration.md`, jamais un blanc.

### Motif du refus — recopié depuis `27-DECISION-claude-orchestration.md` (§6, Verdict)

> **REFUS MOTIVÉ.** Le critère FAIL n°2 (« le run réel diverge du chemin inline : artefacts
> différents, erreur non récupérée, worktree non nettoyé ») est constitué sur deux de ses trois
> formes simultanément — artefacts différents (aucun commit de worker, aucun `SUMMARY.md`, aucun
> merge vers l'arbre principal) et worktree non nettoyé — malgré un franchissement irréprochable de
> l'échelle des 7 gates (PASS n°1) et une Décision A confirmée sûre (PASS n°3). Les critères FAIL sont
> une disjonction : une seule condition suffit, et elle est ici doublement constituée. Ce n'est pas un
> « PASS partiel » — ce cas suppose une Décision A *incertaine*, or elle a été tranchée sans ambiguïté
> par l'observation 2.

Contexte chiffré du run à l'origine de ce constat (§4 de la décision, hors verdict, pour mémoire) :
run réel conduit via l'outil Workflow (`run ID wf_fea42b76-3e2`), terminé en 32 s, 2 agents
parallèles, 0 erreur, échelle des 7 gates franchie **sans drapeau manuel**
(`{"backend": "workflow", "reason": "workflow_backend_active"}`, SDK `0.3.223` résolu par la
persistance option 3 de `GSD_AGENT_SDK_VERSION` posée dans `~/.claude`) — le franchissement des
gates n'a donc jamais été la cause du refus. Le détail complet des sept gates, des trois observations
et de la table de verdicts vit dans `27-DECISION-claude-orchestration.md`, pas ici.

### Déclencheur objectif de reprise — recopié depuis `27-DECISION-claude-orchestration.md` (§6, « Déclencheur objectif de reprise »)

> Sur le patron des capacités dormantes refusées en Phase 24 (GSDA-06, GSDA-08, GSDA-10) : le refus
> ne porte pas de date de réexamen, il porte une **condition factuelle**. Rouvrir
> `claude_orchestration` **ssi**, dans cet ordre, les deux faits suivants sont établis par un nouveau
> run réel — pas supposés :
>
> 1. **Le brief émis pour un plan dispatché via l'outil Workflow embarque le protocole d'exécution
>    GSD complet** (a minima l'équivalent de `execute-plan.md` : commit atomique par tâche,
>    `SUMMARY.md` écrit, protocole de commit respecté) — pas seulement `agentType: "gsd-executor"`
>    sur un brief d'une ligne, tel qu'il l'était dans ce spike.
> 2. **Un mécanisme de merge et de nettoyage existe côté orchestrateur** pour les worktrees du run
>    Workflow qui contiennent des changements (commités ou non) — pas seulement l'auto-nettoyage
>    natif de l'outil, qui ne couvre que les worktrees inchangés (confirmé en creux par l'observation
>    « Décision A » de ce document).
>
> Tant que ces deux faits ne sont pas établis sous un run réel, la divergence observée au §4 se
> reproduira à l'identique : c'est un défaut structurel du couplage (brief jouet + outil Workflow),
> pas un aléa d'exécution. **La décision de persistance de `GSD_AGENT_SDK_VERSION` (option 3, §2bis)
> reste acquise** — elle n'est pas remise en cause par ce refus et n'a pas besoin d'être rejouée à la
> reprise.

### Protocole prévu, jamais exécuté — conservé tel quel pour la reprise

Le protocole ci-dessous a été posé par le plan `27-04` avant que le verdict de `27-05` ne soit connu.
Il reste valide et **inchangé** pour le jour où le déclencheur ci-dessus sera satisfait — un différé
nommé, pas une réécriture à refaire de zéro.

1. **Même manifeste des deux côtés** : `27-mesure/waves-toy.json`, l'étalon posé par la Tâche 1 du
   plan `27-04` — jamais reconstruit à la volée, jamais un manifeste différent entre l'avant et
   l'après.
2. **Identifiant de run fixe** pour chaque répétition, afin que chaque exécution soit individuellement
   re-dérivable (`--run-id` distinct et nommé par répétition, jamais réutilisé entre deux mesures
   différentes).
3. **Au moins deux répétitions par côté** (inline et `claude_orchestration` activé), pour amortir la
   variance d'un run à l'autre — aucune garantie de stabilité inter-run n'existe à ce jour (cf. limite
   3 du Bloc 2, qui s'applique également ici).
4. **Conditions d'exécution à consigner** : date, commit de base, état de `.planning/config.json` au
   moment de chaque répétition (le bloc `claude_orchestration` doit être présent et actif pour les
   répétitions « après », absent pour toute répétition « avant » réutilisée en contrôle).
5. **Chiffres bruts et écart** : mêmes colonnes que le Bloc 2 (hash court, horodatage, écart), plus la
   comparaison inline vs activé sur le même corpus.
6. **Verdict `backend` relevé avant chacune des deux répétitions côté workflow**, pas une seule fois
   pour les deux (garde-fou ajouté par ce plan, `27-06`, suite à revue B3) : seul un verdict
   `workflow` fait d'un run une mesure du côté workflow — un run silencieusement retombé sur `inline`
   est un incident à écrire, jamais une moyenne à calculer en silence avec l'autre répétition.
7. **Limites** : reconduire explicitement les limites 1 à 4 du Bloc 2 (elles s'appliquent à toute
   mesure d'horloge par commit, pas seulement à celle-ci), et ajouter toute limite propre au protocole
   contrôlé (ex. écart introduit par l'activation elle-même, coût du premier appel à froid) — ainsi
   que la limite propre au corpus jouet, écrite en toutes lettres au §Livrable 5 de `27-RESEARCH.md` :
   le corpus étalon porte des briefs triviaux et mesure donc surtout le **coût fixe du dispatch**, pas
   le gain sur des plans de taille réelle. Cette limite s'écrit, elle ne se compense pas.

### Les deux garde-fous d'énoncé, valables quel que soit le résultat

- **Le plafond de la Phase 24 (3,00×, Bloc 1) ne sera jamais présenté comme un gain d'horloge** —
  c'est une compression d'étages, et cette distinction reste vraie que la mesure ait eu lieu ou non.
- **L'estimation 1,8-2,5× de l'option 2** (citée dans `27-CONTEXT.md`/`27-RESEARCH.md` pour l'option
  d'activation de `claude_orchestration`) reste, de ce fait, **étiquetée estimée et jamais mesurée** :
  aucun chiffre réel n'a remplacé cette estimation, puisque l'A/B n'a pas eu lieu. Le statut ne
  changera qu'à la reprise, une fois le déclencheur ci-dessus satisfait et le protocole ci-dessus
  exécuté.

### État de la capability à la clôture de ce bloc

`claude_orchestration.enabled` reste à `false` dans `.planning/config.json`, tel que posé par le
plan `27-05`. Ce plan (`27-06`) ne touche pas cette clé — voir « Disjonction d'écriture déclarée » de
`27-06-PLAN.md` : ce plan n'écrit que ce bloc 3, aucun autre fichier.

---

*Phase : 27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision*
*Plan producteur du Bloc 1 (re-dérivation) et du Bloc 2 (mesure) : 27-04*
*Plan consommateur du Bloc 3 (activation) : 27-05 · Plan producteur du Bloc 3 (mesure après) : 27-06*
