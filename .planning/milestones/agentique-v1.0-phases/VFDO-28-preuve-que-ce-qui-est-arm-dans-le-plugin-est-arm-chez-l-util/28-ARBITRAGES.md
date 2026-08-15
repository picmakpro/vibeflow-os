# Phase 28 — Arbitrages

**Posés :** 2026-08-10 · **Statut :** tranchés, non rediscutables au plan
**Convention :** reprise de `24-ARBITRAGES.md` (Phase 24). Ce fichier existe pour que la décision
survive à la mission — un plan se périme, un arbitrage écrit ne se re-débat pas.

> **Portée.** Ces neuf arbitrages ferment des points que `28-CONTEXT.md` avait laissés en
> « Claude's Discretion » ou que `28-RESEARCH.md` a rouverts en « Open Questions ». Ils **priment**
> sur les recommandations de la recherche partout où les deux divergent — la divergence est nommée
> à chaque fois. Tous les faits cités ont été **re-vérifiés sur disque le 2026-08-10** avant écriture.

---

## Table de synthèse

| # | Point tranché | Décision | Prime sur |
|---|---|---|---|
| A-1 | Mécanisme de liaison (D-02b) | Jointure par **identifiant de précondition** | les 4 autres mécanismes |
| A-2 | Nommage de la déclaration côté script | `# vf-provides:` | `# vf-proves:` (28-PATTERNS.md) |
| A-3 | Ce qui déclenche le ROUGE | l'**armement seul**, jamais une déclaration | — |
| A-4 | Le gate exécute-t-il un `ensure-*` ? | **Non** — lecture seule stricte + preuve de discriminance en test | 28-RESEARCH.md Open Question 3 |
| A-5 | Découpage de `check-capability-activation.sh` | **Clos** — aucun seuil ne s'applique | la discrétion D-03 |
| A-6 | `--strict` refuse-t-il une clé de frontmatter inconnue ? | **Non** — le CONTEXT se trompe | 28-CONTEXT.md D-01 l. 63-64 |
| A-7 | Véhicule de D-04 | le job CI `lab-frais`, seul | `--plugin-url`, `validate --strict` |
| A-8 | Plancher anti-vert-à-vide de D-04 | **obligatoire** — l'univers installé est vide aujourd'hui | le cadrage « simple ajout d'étape » |
| A-9 | gsd-core 1.10.0 rouvre-t-il le ré-armement ? | **Non** — mais `baseRef` change de camp | — |

---

## A-1 — Mécanisme de liaison : jointure par IDENTIFIANT de précondition

**Décision.** La liaison artefact ↔ preuve se fait par un **identifiant de précondition** déclaré
des deux côtés, jamais par un chemin ni un nom de fichier :

- `vf-requires: <id>` dans le **frontmatter de l'artefact armé** ;
- `# vf-provides: <id>` en **en-tête du script de preuve** ;
- un **registre = vocabulaire seul** — la liste close des armements et la table des `<id>` légaux,
  **jamais une liste d'artefacts**.

**Modèle.** Debian `Depends:` / `Provides:` sur nom virtuel : un paquet dépend d'une *capacité*, pas
d'un fichier ; n'importe quel paquet peut la fournir, et la capacité disparaît avec son fournisseur.

**Motif décisif.** Toute liaison à un **fichier** rend vert le cas *« le script existe encore mais ne
prouve plus rien »* — c'est #38 rejoué d'un cran. Lier à un `<id>` **déclaré par le script lui-même**
fait disparaître la preuve avec le code qui la portait : on ne peut pas vider un script de sa
substance sans lui retirer sa ligne `# vf-provides:`.

**Motif secondaire, mesuré.** Les artefacts vivent en **deux dispositions** — `plugin/<module>/scripts/`
en distribution, `.claude/scripts/` **à plat** en lab installé (`plugin/_internal/vibeflow-update.sh:341-343`,
glob pur `"$module_dir/scripts/"*.sh` → `"$TARGET_ROOT/scripts/"`). Figer un chemin fabriquerait des
faux verts en lab installé.

**Les quatre mécanismes écartés.**

| Mécanisme | Forme | Pourquoi écarté |
|---|---|---|
| **Convention de nommage** | `isolation:` ⇒ on cherche `ensure-isolation.sh` | D-02b l'interdit nommément (« jamais inférée d'une proximité de nom »). Et `28-RESEARCH.md` A3 mesure que **rien ne vérifie** la convention de préfixe par machine : elle est une coutume, pas un contrat. |
| **Frontmatter nommant le FICHIER** | `vf-precondition: scripts/ensure-x.sh` | Vert dès que le fichier existe. Vider `ensure-x.sh` de son contenu ne casse rien. Et le chemin diverge entre les deux dispositions (cf. motif secondaire). |
| **Registre central d'artefacts** | une table « artefact ↔ script » dans un fichier du dépôt | **Disqualifiant** : un agent d'un autre module jamais inscrit au registre reproduit #38 **littéralement** — c'est le mode d'échec exact (« personne n'a déclaré/inscrit »). Corroboré : la distribution est un **glob** sans roster (`vibeflow-update.sh:342-343`), les suites de tests sont découvertes **par convention** (`.github/workflows/ci.yml:207`). Ce dépôt n'a aucun roster, par doctrine. |
| **Exécution du `ensure-*` par le gate** | le gate lance le script et lit son exit | Écarté par A-4 (lecture seule stricte). Un gate qui exécute du code découvert dans l'arbre est le vecteur fermé en Phase 23 (`build-gsd-capabilities-index.sh` basculé en lecture de texte pour fermer T-23-04-07, RCE). |

**Conséquence pour le plan.** Le registre-vocabulaire est une **liste close écrite à la main**, pas
un index généré. Il énumère (i) les armements surveillés et (ii) les `<id>` de précondition légaux.
Un `vf-requires:` citant un `<id>` hors table est une erreur, pas un vert.

---

## A-2 — Nommage : `# vf-provides:`, pas `# vf-proves:`

**Décision.** La déclaration côté script s'écrit `# vf-provides: <id>`.

**Motif.** `28-PATTERNS.md` propose `# vf-proves:` ; c'est `# vf-provides:` qui est retenu — pair
naturel de `vf-requires:` (le couple se lit sans glossaire) et précédent Debian direct
(`Depends:` / `Provides:`). Le préfixe `vf-` s'aligne sur les clés déjà admises par
`plugin/conductor/scripts/check-agents.sh:158-160` (`vf-internal`, `vf-mcp-consumer`, `vf-mcp-tools`).

---

## A-3 — Le ROUGE ne dépend JAMAIS d'une déclaration

**Décision.** La branche (b) de D-01 (liste close) balaye les armements et **rougit sur l'armement
seul**. `vf-requires:` ne fait que **lever** le rouge ; il ne le déclenche pas.

**Motif.** Un gate dont le rouge dépendrait du bon vouloir d'un déclarant serait **inerte sur le mode
d'échec exact de #38** : « personne n'a déclaré ». C'est la raison d'être écrite de la seconde moitié
de D-01 (`28-CONTEXT.md` l. 59-62) — la déclaration porte l'extensible, la liste close rattrape le
connu ; si la liste close attend elle aussi une déclaration, il ne reste plus rien qui rattrape.

**Conséquence pour le plan.** L'ordre de lecture du gate est : *armement détecté* → *cherche un
`vf-requires:` sur cet artefact* → *cherche un `# vf-provides:` correspondant dans le corpus de
scripts*. Chaque maillon absent laisse le rouge en place.

---

## A-4 — Le gate reste en LECTURE SEULE stricte, et le marqueur seul ne suffit pas

**Décision, en deux moitiés indissociables :**

- **(i)** Le gate n'exécute **aucun** `ensure-*.sh`. Jointure **statique** par `<id>` uniquement.
- **(ii)** Une **tâche du plan doit prouver, dans la suite de tests**, que le `ensure-*` cité **sait
  réellement rendre non-zéro** quand la précondition manque. Un `ensure-*` non discriminant ne doit
  pas pouvoir déclarer `# vf-provides:`.

**Motif de (i).** Exécuter un script découvert dans l'arbre depuis un gate CI est le vecteur déjà
fermé en Phase 23 (lecture de texte substituée à `require()`, T-23-04-07). Ne pas le rouvrir.

**Motif de (ii), mesuré.** Un marqueur statique seul ne prouve rien :
`plugin/design-orchestrator/scripts/ensure-design-deps.sh:59-60` déclare en toutes lettres
*« Contrat de sortie : **toujours exit 0**, SAUF `VF_SCOPE` invalide »* — précondition non satisfaite
comprise. Et son seul câblage machine (`plugin/_internal/vibeflow-update.sh:581-586`) le traite en
**best-effort à l'install** : les deux branches loggent, aucune n'échoue. Accepter sa seule présence
comme preuve reviendrait à écrire un gate vert sur un script incapable de rougir.

**Divergence assumée avec `28-RESEARCH.md` Open Question 3**, qui recommande d'exiger un mode
`--verify` **« et de l'exercer depuis le gate »**. La seconde moitié de cette recommandation est
**refusée** (elle enfreint (i)) ; la première est conservée comme forme possible.

**Latitude laissée au plan.** La **forme** est libre — mode `--verify` à exits distincts sur le patron
mesuré de `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh:79-84`
(`0 = conforme · 1 = manquant · 3 = INDÉTERMINÉ`, avec la note explicite *« un faux vert serait pire
que l'absence de vérification »*), ou toute autre. La **propriété exigée** est la **discriminance
prouvée**, pas une signature particulière.

---

## A-5 — Découpage de `check-capability-activation.sh` : CLOS, aucun seuil ne s'applique

**Décision.** **N'invoque aucun seuil** pour justifier un découpage. Le point de discrétion D-03
(« si l'extension franchit le seuil de `check-file-size.sh` ») est **sans objet**.

**Motif, vérifié deux fois sur disque :**

- `plugin/software-architecture/scripts/check-file-size.sh:27` —
  `CODE_EXT_RE='\.(ts|tsx|js|jsx|mjs|cjs|py|go|rb|java|kt|swift|rs|php)$'` : **pas de `.sh`**.
- `…/check-file-size.sh:33,43` — `check_one()` fait `is_code_file "$f" || return 0` : sortie
  **silencieuse** sur tout non-code.
- `…/check-file-size.sh:28,70` — `SCAN_DIRS=(src app lib features)` : ne couvre pas
  `plugin/*/scripts/`.

Les **443 lignes** mesurées (`wc -l`, 2026-08-10) ne franchissent donc rien, et N lignes de plus non
plus.

**Si le plan découpe quand même**, le seul motif recevable est la **lisibilité, argumentée** — et il
doit alors migrer les **3 appelants**, mesurés exhaustivement :
`.github/workflows/ci.yml:342`, et `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh`
T14d (d) et (e) (`:2128` résout `CAPACT`, `:2141-2143` juge (d)).

---

## A-6 — Correction de prémisse : `--strict` ne refuse PAS une clé de frontmatter inconnue

**Le CONTEXT est faux sur ce point.** `28-CONTEXT.md` §Canonical References et D-01 (l. 63-64)
affirment que `check-agents.sh` **refusera** en `--strict` une clé de frontmatter inconnue, et en
tirent un prérequis bloquant (« devra l'admettre dans ses clés `KNOWN` »).

**Mesuré sur disque :**

```
plugin/conductor/scripts/check-agents.sh:618-620
    for k in fm:
        if k not in KNOWN:
            warnings.append(f"{base} : champ inconnu du runtime — {k} …")
```

C'est un `warnings.append` **nu** — **sans** le patron `(errors if strict else warnings).append(msg)`
employé partout ailleurs, notamment aux lignes **575** et **616** du même fichier. Et seul `n_err`
sort en 1 (`:673-677`) ; la sortie normale est `sys.exit(0)` (`:679`).

**Conséquence.** L'ajout de la clé `vf-requires` aux `KNOWN` (`:158-160`) est **hors chemin critique** :
souhaitable pour le bruit de warning, **jamais un prérequis bloquant**. **La séquence est libre** — le
plan peut poser la clé avant, après, ou dans la même tâche que son admission.

*(Note annexe mesurée : `isolation` **est déjà** dans `KNOWN` (`:160`) — l'interdiction de D-06 vit
ailleurs, dans la garde dédiée `:528-549`, pas dans la liste des clés connues.)*

---

## A-7 — `claude plugin install --plugin-url` n'existe pas ; `lab-frais` est le seul véhicule de D-04

**Décision.** Le job CI `lab-frais` (`.github/workflows/ci.yml:620`) est le **seul** véhicule
d'*as-installed testing* de cette phase.

**Motif.** Sondé en 2.1.226 : `--plugin-url` **n'existe pas** — l'outillage plateforme évoqué en
option par `28-CONTEXT.md` D-04 est écarté. `claude plugin validate --strict` ne valide qu'un
**manifeste** : hors sujet pour une question de cohérence armement ↔ précondition.

---

## A-8 — D-04 doit poser un plancher anti-vert-à-vide : l'univers installé est VIDE aujourd'hui

**Décision.** Le plan **DOIT** poser un plancher qui **rougit quand l'univers balayé est vide**, et
**DOIT** régler le cas `.planning/config.json` absent.

**Motif, mesuré ce jour :**

| Fait | Mesure | Conséquence |
|---|---|---|
| Fermeture de `conductor` | **7 modules** (`bash plugin/_internal/resolve-deps.sh conductor`, rejoué) : `audit-architecture conductor consolidator infrastructure-audit planning-core skill-creator validator` | `dev-orchestrator` et `design-orchestrator` **absents** — le gate n'est même pas installé dans `lab-frais` |
| Agents posés par cette fermeture | **0 armement** parmi eux | rien à juger |
| `.planning/config.json` dans un lab neuf | **absent** — `ci.yml:647-648` le dit explicitement (*« un lab tout juste installé n'a pas encore de .planning »*) | le gate sort **2** avant toute lecture (`check-capability-activation.sh:200-203`) |
| Fermeture de `dev-orchestrator` | **9 modules** (mêmes 7 + `dev-orchestrator` + `design-orchestrator`) | récupère `vf-coder`, `vf-reviewer`, `vf-auditer`, `vf-dev-manager` et la chaîne design |

Sans plancher, une étape ajoutée telle quelle à `lab-frais` **rendrait vert à vide** — exactement le
mode d'échec que la phase existe pour fermer.

**Latitude laissée au plan.** La **forme** est libre : étape ajoutée au job existant, second job, ou
fermeture installée différente. **Contrainte de report** : le cadrage D-04 disait « ajout d'une étape
au job » et notait la réversibilité sur cette base ; si la solution retenue va au-delà (second job,
élargissement de la baseline installée), le plan doit le **signaler explicitement** — c'est une
remontée à l'humain, pas une décision de plan. `28-RESEARCH.md` Open Question 4 recommande le
**second job / la seconde étape** plutôt que la modification de la baseline existante, *« le vert
actuel de Gate C étant un acquis à ne pas troubler »*.

---

## A-9 — gsd-core 1.10.0 ne rouvre RIEN, mais `baseRef` change de camp

**Décision, en deux volets, tous deux à traiter :**

**(i) Interdiction absolue** d'y voir un argument pour ré-armer `isolation: worktree`. Le verrou
`open-gsd/gsd-core#3302` porte sur le **retour des commits** d'un worker isolé — la dégradation
gracieuse ne le résout pas, elle rend seulement l'absence de réglage moins destructrice.

**(ii)** C'est l'item de discrétion « **précondition dure vs tuning à défaut sûr** » : le plan doit le
**trancher explicitement et l'écrire**.

**Faits mesurés.** `gsd-tools worktree base-check` / `set-baseref` existent en 1.10.0 ; et
`~/.claude/gsd-core/bin/lib/worktree-base-ref.cjs:96-100` **dégrade en séquentiel avec message**
au lieu de casser en silence. `baseRef` glisse donc de « précondition dure » vers « tuning à défaut
sûr ».

**Nuance mesurée qui n'est ni dans le CONTEXT ni dans le mandat**, et qui pèse sur l'arbitrage :
`worktree-base-ref.cjs:100` (`MSG_HEAD_UNRESOLVABLE`) écrit noir sur blanc que
`worktree.baseRef:"head"` **« silences this check without verifying the base — it skips the comparison
rather than resolving it »**. Poser le réglage n'est donc pas *satisfaire* la précondition : c'est
*taire la vérification*. Un `ensure-*` qui se contenterait de poser `baseRef: "head"` prouverait donc
la distribution d'un **silencieux**, pas d'une garantie — à dire dans les bornes du gate (D-01b).

**Garde-fou contre le cas de preuve creux.** Si le plan conclut que `baseRef` est désormais un défaut
sûr, il **n'évacue pas silencieusement** la ligne `isolation: worktree` de la liste close. Deux issues,
pas trois : **soit** il la garde avec un motif réécrit, **soit** il fonde le fixture D-06 sur un
armement dont la précondition est réellement dure, **et il le dit**. Jamais un cas de preuve creux.

**Recommandation de `28-RESEARCH.md` Open Question 2, laissée ouverte au plan :** trois verdicts au
lieu de deux — ROUGE (armé, aucune preuve, aucun défaut sûr) · VERT (preuve `ensure-*` exerçable) ·
INDÉTERMINÉ non bloquant (défaut sûr documenté et dégradation gracieuse prouvée). Le gate porte déjà
la doctrine des trois états. Le plan tranche ; il ne l'écrase pas en binaire sans motif écrit.

---

## Ce que ces arbitrages ne tranchent pas

Reste à la main du plan, et doit y être écrit noir sur blanc :

1. **La frontière de corpus D-06.** Elle est **vide aujourd'hui**, mesurée :
   `plugin/conductor/scripts/check-agents.sh:628` globe `<agents_dir>/*.md` et ne lit ni `config.json`
   ni l'index ; `plugin/dev-orchestrator/scripts/check-capability-activation.sh:189-193` lit trois
   artefacts et **aucun agent**. Étendre le second aux frontmatters le fait **entrer dans le corpus
   du premier**. Le plan doit dire **quelle garde porte quelle règle** (interdiction dure vs relation
   conditionnelle armement ↔ précondition), **pourquoi l'autre subsiste**, et le test D-06 doit
   établir que **le nouveau gate rougit de son propre chef** — pas que l'ancien le fait encore.
2. **L'univers de balayage à deux dispositions.** Les armements `mcp__*` n'existent **qu'après**
   `inject-mcp-tools.sh` : mesuré, la seule occurrence de `mcp__` dans `plugin/*/agents/*.md` est
   une **phrase de prose** (`plugin/dev-orchestrator/agents/vf-reviewer.md:45`), pas un armement.
   Deux pièges d'un coup — un gate qui ne balaye que la distribution rendrait **vert** le lab où
   l'armement est réellement posé, et un gate qui cherche le littéral `mcp__` rougirait sur de la
   **prose**. Prévoir `plugin/*/agents/` **et** `.claude/agents/`. Corpus distribué mesuré : **31**
   agents = **25** sous `plugin/*/agents/*.md` + **6** `plugin/<module>/AGENT.md`
   (`validator`, `dev-orchestrator`, `design-orchestrator`, `skill-creator`, `kpi-analyst`, `conductor`).
3. **Le 3ᵉ discriminant dans l'`awk`.** Le script discrimine par `FILENAME == IDX`
   (`check-capability-activation.sh:318`) et **tout le reste** tombe dans le bloc corpus (`:355`)
   **sans condition**. Une 3ᵉ famille de fichiers (frontmatters) exige un discriminant explicite,
   sinon faux positifs silencieux des règles existantes.
4. **Le plancher anti-vert-à-vide sur chaque règle neuve**, patron `:376-388` : registre illisible,
   table vide, zéro artefact balayé, zéro `# vf-provides:` ⇒ sortie « NON VÉRIFIABLE » (exit 2),
   jamais un repli vert.
5. **La garde `jq` sort en 2 avant toute lecture** (`:204-207`) alors que les règles neuves n'en ont
   pas besoin : placer le bloc avant la garde, ou scinder les motifs d'exit 2.
6. **La comparaison d'`<id>` à frontière** — `occ()` / `isid()` (`:266-284`), jamais `index()` nu :
   `settings.worktree.baseRef` est un **préfixe** de `settings.worktree.baseRef.head`.
7. **Les skills n'ont aucun linter de clés de frontmatter.** Si `vf-requires` doit être porté par des
   `SKILL.md`, ou bien le plan le couvre, ou bien il l'écrit dans les **bornes** du gate (D-01b).
8. **D-01b — le gate écrit ses propres bornes** : le nom du pattern *as-installed testing* (D-04) et
   la limite honnête « le gate prouve une couverture **déclarée**, pas une couverture **effective** »
   si A-4(ii) ne la ferme pas complètement.

---

*Phase 28 · arbitrages posés le 2026-08-10 · faits re-vérifiés sur disque avant écriture*
</content>
