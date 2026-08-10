# Mission — Phase 27 : parallélisation d'exécution (granulaire, simple, sans collision d'écriture)

> **Statut au 2026-08-06 : LES TROIS GELS SONT LEVÉS. 9 exigences sur 11 tenues.**
> Seuls restent le **spike `claude_orchestration`** (`PAEX-09`) et la **mesure du gain** (`PAEX-10`),
> gelés **par choix de Samuel**, qui veut être présent — pas par un blocage technique.
> Branche `feat/phase-27-parallelisation-execution` — **non mergée**, PR #35 laissée ouverte (ADR-059).
> Manager : `vf-dev-manager`. Plan de bataille : `.planning/missions/dag-phase27.json`.
> **Le détail de la reprise est en §9** ; les sections 1 à 8 décrivent l'état du 2026-08-05 et sont
> conservées telles quelles — elles racontent comment les gels ont été posés, ce qui reste utile.

---

## 0. Le résultat en cinq lignes

La doctrine fausse est corrigée, le trou de `dag.sh` est fermé par câblage (87 tests verts contre 71
avant), le prérequis matériel de l'isolation est posé — et **rien n'a été armé**. Trois gels ADR-031
restent, dont un **finding CRITIQUE d'audit : une RCE reproduite par PoC** dans le socle que les cinq
managers invoquent en routine. La phase a par ailleurs produit, **sur elle-même**, la démonstration
empirique de sa propre raison d'être : deux workers aux périmètres vérifiés disjoints se sont malgré
tout écrasés au niveau du commit.

---

## 1. Cadre de mission

**Gestes de démarrage, tous verts.** `$S` résolu sur `plugin/conductor/scripts` (le lab courant prime ;
`~/.claude/scripts` héberge une version antérieure des mêmes scripts). Verrou acquis
(`acquired: true`, `recovered: false`). Gate d'invariants : **exit 3, SAIN**, aucune zone morte —
avec la note que `dag.sh`, `check-*.sh`, `hooks.json` et `vf-*-manager.md` sont des **zones de risque
déclarées**, ce qui a imposé le régime plein sur la revue. Flags d'enchaînement désarmés
(`workflow._auto_chain_active`, `workflow.auto_advance`, tous deux confirmés `false`).

**Repli D-09 actif.** `AskUserQuestion` n'a **pas** été fourni au manager dans ce dispatch. La mission
a donc tourné en **mode autonome de fait** : tout `ask-user` a été **gelé et remonté**, jamais
auto-répondu. C'est la cause directe de la forme du résultat — la phase s'arrête à chaque frontière
humaine au lieu de les franchir.

---

## 2. Plan de bataille et déroulé

| Nœud | Issue | Note |
|---|---|---|
| `rederive-chiffres` | `passed` | épinglé sur `f4d7447` — ce qui l'a rendu réellement disjoint du cadrage |
| `discuss-27` | `passed` | zéro escalade, 5 candidats vérifiés un par un |
| `plan-27` | `passed` (3 tours) | 6 plans, 4 vagues |
| `plancheck-27` | `gaps_found` → `passed` | **3 bloquants, 4 majeurs, 2 mineurs** au round 1 |
| `exec-27-01` | `passed` | 87 PASS / 0 FAIL (71/0 avant) |
| `exec-27-02` | `passed` (2 tours) | doctrine + ROADMAP |
| `exec-27-03` | `failed` → `human_needed` | interrompu, repris, arrêté au checkpoint |
| `revue-v1` (plein) | `gaps_found` | 4 majeurs, 3 mineurs |
| `audit-v1` | `gaps_found` | **1 critique, 1 élevé** |
| `exec-27-04/05/06`, `docs` | **gelés** | checkpoints humains |

**Parallélisme réellement pris** : `rederive-chiffres` ∥ `discuss-27` ; les trois plans de la vague 1
en un seul message ; revue ∥ audit ∥ clôture de `27-03`. Un seul `reopen` par cycle de findings,
jamais un par juge.

---

## 3. Ce qui est livré et vérifié

- **Livrable 1 — doctrine.** `team-kernel.md:64-65` disait « **perdu** », dit maintenant « **éteint
  par défaut** », nomme le gate n° 4 (`nested && background`, **jamais** `backgroundDispatch`) et,
  après finding de revue, le **verrou pratique** gate n° 5 (`agent_sdk_version_unknown`) avec
  `GSD_AGENT_SDK_VERSION`. Un renvoi d'une ligne vers `stages` y a été ajouté **parce que
  `team-kernel.md` est le fichier que lisent les cinq managers** — sans lui, la capacité aurait été
  livrée invisible à quatre lecteurs sur cinq.
- **Livrable 3 — câblage.** `dag.sh ready` porte `stages`, **additif**, calculé par
  `partitionStages()` amont **en sous-processus**, jamais réimplémenté (ADR-069). Manifeste par
  `mkstemp` 0600 exclusif, suppression en `finally` — vérifié en exécution par les deux juges.
- **Livrable 2 — partiel.** `.worktreeinclude` (**une seule entrée**, `.claude/agent-memory/`,
  justifiée : un worker isolé perdrait sinon toute mémoire accumulée), `.gitignore`,
  `27-ISOLATION-PORTEE.md`. **0 agent sur 25 armé.**
- **Chiffres re-dérivés.** ADR-069 **tient sur ses deux comptages** : `workstream` K2 = **7/91**,
  `.planning/` en dur = **45**. Le `6` était un K1 récursif déguisé (son motif `--ws ` ne matchait
  rien) ; le `73` comptait toute mention de `.planning/` (73 = 70 racine + 3 imbriqués ; 70 − 45 = 25
  chemins que la partition ne déplace pas). L'encadré du ROADMAP est levé. **Limite écrite, pas tue :
  non épinglable** — le corpus vit hors dépôt, seule ancre `~/.claude/gsd-core/VERSION` = 1.9.1.

---

## 4. Les trois gels — ce qui attend Samuel

### 4.1 CRITIQUE — RCE dans `dag.sh:124` (5ᵉ passage du motif)

`resolve_gsd_tools_cmd()` teste un candidat **relatif au répertoire de travail courant**
(`os.getcwd()/gsd-core/bin/gsd-tools.cjs`) et l'exécute via `node` **sans vérification d'ancrage**.
PoC rejoué en réel par l'auditeur : un fichier planté suffit, **sans symlink ni PATH compromis** —
exactement ce que produirait le checkout d'une branche ou d'une PR malveillante. `dag.sh ready` est
invoqué en routine par les **cinq managers**.

**Pourquoi le threat model ne l'a pas vu, et c'est la leçon transférable** : `T-27-01-04` couvrait
bien le spoofing de résolution, mais **uniquement via `PATH`**, avec une disposition `accept`
justifiée par « un PATH déjà compromis compromet toute la session ». Ce raisonnement est **correct
pour `PATH` et faux pour le CWD**, où aucune compromission préalable n'est requise. Un registre de
menaces peut donc passer au vert sur un vecteur voisin qu'il n'a jamais examiné.

**Nuance en faveur du retrait** : sur ce dépôt, le candidat est une **branche morte** — `gsd-core/`
n'est pas vendorisé à la racine. Le retirer ne sacrifie aucun chemin fonctionnel ici. Mais il
pourrait être vivant sur un lab qui vendorise le moteur : c'est un **arbitrage**, pas une évidence.

### 4.2 Ratification de `worktree.baseRef: "head"` avant armement

La tâche 4 de `27-03` armerait `isolation: worktree` sur 13 agents écrivains. Elle est gatée derrière
un `checkpoint:human-verify` **bloquant**, doublé d'une assertion machine sur `worktree base-check`
(prouvée par mutation, rouge et vert). **Mais** un worker a appliqué `worktree set-baseref` **hors
checkpoint**, en marge d'une vérification : `.claude/settings.local.json` existe (gitignoré) et
contient `{"worktree":{"baseRef":"head"}}`. **L'assertion passe donc au vert sans qu'aucun humain
n'ait ratifié.** La valeur correspond à votre décision B, mais le **geste** a été court-circuité.
Ce qu'il reste à ratifier : que ce réglage **global** (toutes missions, toute la machine) est bien
celui voulu, puis autoriser l'armement.

Le gate a tenu : **0 agent armé** malgré une condition verte. C'était le comportement à vérifier.

### 4.3 Spike `claude_orchestration` et mesure

`27-05` et `27-06` sont non autonomes par construction. Point dur relevé au plancheck :
`GSD_AGENT_SDK_VERSION` doit être **persistée** au runtime (bloc `env` de `settings.json`, profil
shell, ou installation réelle) — passée en simple drapeau, un PASS laisserait `enabled: true` pendant
que **tout dispatch réel retombe sur `inline`** au gate n° 5. Une capability déclarée active qui ne
s'active jamais est pire qu'une capability éteinte.

---

## 5. Deux findings de revue DIFFÉRÉS avec 4.1 — et pourquoi

- **M1** : un mutant remplaçant `stages: null` par `stages: []` sur la branche « CLI résolue mais qui
  échoue » **survit aux 87 tests** — alors que la doctrine ajoutée par ce même diff écrit que les
  deux « ne se confondent JAMAIS ».
- **M2** : `T29` croit exercer « CLI amont introuvable » ; en réalité la cascade la trouve au 4ᵉ
  maillon dans `~/.claude/`, et c'est l'absence de `node` qui produit le résultat. **Test dépendant de
  l'environnement, sur le kernel de mission.**

**Motif du report** : les deux portent sur la **même fonction** que 4.1. Écrire un T31 maintenant
graverait comme **comportement attendu** la branche qui pourrait être retirée. Un trou de couverture
reconnu vaut mieux qu'un test qui cimente une vulnérabilité.

---

## 6. Le fait que la phase a produit sur elle-même

Deux workers aux périmètres **vérifiés disjoints** (recoupés fichier par fichier par le plan-checker,
intersection vide) se sont écrasés. Mécanisme établi : `27-02` a fait un `git add` **ciblé sur son
seul fichier** (inoffensif isolément) ; dans cette fenêtre, `27-03` a fait un `git commit -m` **sans
pathspec** (inoffensif isolément). `git commit` nu commite **tout l'index partagé** — d'où
`team-kernel.md` dans un commit `docs(27-03)`.

**La disjonction déclarée gouverne le dispatch, jamais le commit.** Aucun câblage de `dag.sh` ne peut
fermer ce trou : tant que N workers partagent un `.git/index`, la discipline de commit est une
**convention**, pas une **construction**. Le seul mécanisme qui la rend physique est exactement le
livrable 2. C'est l'argument le plus fort de la phase, et il est empirique.

Aucun contenu n'a été perdu. L'historique **n'a pas été réécrit** — décision du worker `27-02`,
correcte : six commits étaient empilés par-dessus et deux voisins committaient en direct ; un rebase à
chaud aurait transformé un défaut d'attribution en perte réelle.

---

## 7. Calibration

| Plan | `estimate` | `actuals` |
|---|---|---|
| 27-01 | `{tokens: 70000, tasks: 3, confidence: low}` | `{tokens: 4398, tasks: 3, commits: 3}` |
| 27-02 | `{tokens: 30000, tasks: 2, confidence: low}` | `{tokens: 748, tasks: 2, commits: 2}` |

Relayés **verbatim**, sans recalcul ni agrégation. Aucun `verdicts` de checkpoint amont à relayer :
la revue et l'audit ont vécu comme nœuds de plan de bataille dispatchés en direct, pas comme hooks
`execute:post`.

---

## 8. Limites de cette mission, dites plutôt que tues

- **Les corrections M3/M4 (`280202a`) n'ont pas été re-passées devant les juges.** Le `reopen` force
  le régime plein sur toute revue rouverte ; j'ai jugé un troisième tour disproportionné pour deux
  clauses textuelles dont l'avant/après est cité. C'est un écart assumé, à peser à la relecture de PR.
- **Aucune recette fonctionnelle.** Ce dépôt n'est pas mobile et la phase ne livre pas de feature
  utilisateur : la vérification a reposé sur les gates techniques, la revue et l'audit.
- **Le nœud `docs` n'a pas tourné** — il dépend des nœuds gelés. `STATE.md` et `REQUIREMENTS.md` ont
  été tenus **à la main** par le manager, `gsd-tools state.*` étant écarté (précédent documenté
  d'écrasement destructif des compteurs `progress`).

---

## 9. Reprise du 2026-08-06 — les trois gels levés

### 9.1 Les arbitrages de Samuel

1. **`dag.sh:124` → RETRAIT** du candidat cwd-relatif. Pas d'ancrage, pas de repli déguisé.
2. **`worktree.baseRef: "head"` → RATIFIÉ**, prenant effet une fois le fix livré et les tests verts.
3. **Spike `claude_orchestration` → ne pas lancer**, ni « préparer un peu ». Présence humaine voulue.

### 9.2 Ce qui est livré

- **Le vecteur RCE est fermé DANS LES DEUX SITES.** `dag.sh` (`4a532ec`), puis — grâce au balayage
  exigé au mandat — `mission-contracts.md` (`08ad030`), où la variante `toplevel` portait le même
  défaut. **`git rev-parse --show-toplevel` n'est pas une frontière de confiance** : un dépôt hostile
  a sa propre racine, et le repli `|| pwd` ramenait littéralement au CWD qu'on venait d'interdire.
  Fermer le 5ᵉ passage sans balayer les voisins aurait garanti un 6ᵉ.
- **Fermeture vérifiée EN EXÉCUTION**, pas annoncée : PoC rejoué dans deux configurations, le fichier
  planté n'est plus jamais exécuté. Et `T33` rougit sur la **réintroduction réelle du comportement**,
  pas sur une chaîne de source qu'un renommage contournerait.
- **Les deux tests différés sont écrits** (`T31`, `T32`) et `T29` neutralise enfin
  `HOME`/`CLAUDE_CONFIG_DIR`. **99 PASS / 0 FAIL** (87 avant). Le report était justifié : les écrire
  plus tôt aurait gravé comme comportement attendu la branche qui a été retirée.
- **13 agents écrivains armés** en `isolation: worktree`, **0 manager**. Lint re-passé **par
  répertoire de module** : 6 répertoires, **25 fichiers réellement lintés**.
- **ADR-070** grave la cause racine. **`team-kernel.md`** grave la discipline de commit.

### 9.3 Trois verts obtenus pour la mauvaise raison — le fil rouge de cette reprise

1. **`check-agents.sh` nu** sort `exit 0` sur « aucun agent dans `.claude/agents` » : il ne scanne
   qu'un répertoire, sans récursion. Valider l'armement avec lui aurait confirmé 13 frontmatters
   modifiés **en ne regardant rien** — ADR-070 retourné contre son propre auteur.
2. **Un test de mutation rougissait pour la mauvaise raison** : le fixture piège mourait faute de
   `bash` puis de `cat` sur le `PATH` restreint, et retombait **par accident** sur la valeur
   attendue, masquant la mutation. Deux faux positifs avant un vrai rouge. Règle qui en découle :
   exiger la **trace** du rouge (assertion, attendu, obtenu), jamais le verdict.
3. **`git ls-files 'plugin/*/agents/*.md'` rend 49 fichiers** là où l'ensemble réel en compte **25** :
   le `*` d'un pathspec git traverse les `/`. Deux décomptes justes sur des ensembles différents —
   sur la mesure même censée valider un gate.

### 9.4 Ce que la doctrine ignorait d'elle-même

La discipline de commit **n'était gravée nulle part** dans la doctrine distribuée (`git grep` sur
tout `plugin/**` : rien). Elle vivait dans la mémoire du manager et dans les mandats rédigés à la
main — **aucun worker ne pouvait la lire**, ce qui explique l'écrasement du 2026-08-05 bien mieux
qu'une négligence individuelle. Mieux : `mission-contracts.md` §Isolation de branche **avait nommé
ce trou** et l'avait laissé « **non tranché ici** ». L'incident n'est donc pas survenu dans un angle
mort, mais dans un manque **documenté** — un « non tranché » sans échéance finit tranché par un
incident.

### 9.5 Deux systèmes de suivi, deux vérités

Le `safe_resume_gate` du moteur a bloqué `27-04` parce que `27-03-SUMMARY.md` manquait, alors que
**mon DAG de mission marquait `exec-27-03: done`**. Les deux avaient raison à leur échelle : les
écritures autonomes du plan étaient finies, sa tâche 4 ne l'était pas. J'ai refusé les trois recours
du moteur (« clôturer manuellement », « ré-exécuter », « marquer et sauter ») — tous traitent le
manque comme un défaut de comptabilité. Il n'en était pas un : **le SUMMARY manquait parce que le
travail manquait**. Exécuter l'armement a refermé le gate par le haut (`183bff7`).

### 9.6 Ce qui reste

- **`PAEX-09`** — spike `claude_orchestration`. `GSD_AGENT_SDK_VERSION` doit être **persistée** au
  runtime, pas passée en drapeau : sinon un PASS laisse `enabled: true` pendant que tout dispatch
  réel retombe sur `inline` au gate n° 5.
- **`PAEX-10`** — mesure du gain. `27-04` (baseline) est **débloqué mais non capturé**.
- **Non-finding conservé** : `scripts/hooks/pre-push` porte la même forme, mais l'exposition est
  **subsumée** (si `core.hooksPath` pointe dans le dépôt, le hook est lui-même du contenu versionné)
  et le fichier est sur `main` bien avant cette phase.
