# Investigation `dag.sh --scope` — précondition transverse (Phase 29)

**Date** : 2026-08-15
**Statut** : livrable durable, consolidé depuis `29-RESEARCH.md` §« Investigation `dag.sh --scope`
— précondition transverse » (l.341-448). Ce rapport ne relance aucune investigation neuve : il
consolide une recherche déjà sourcée, pour qu'un lecteur qui n'a ni la session ni `29-RESEARCH.md`
sous la main puisse s'en servir seul.

**Pourquoi ce rapport existe** : D-03 (`29-CONTEXT.md`) pose « zéro régression autorisée sur
`dag.sh --scope` » comme précondition **transverse** à tout geste G1 de la Phase 29 — le mécanisme
porte le dispatch parallèle des périmètres disjoints du team-kernel en production, chez les
utilisateurs du plugin. L'investigation n'est donc pas un préambule jetable mais un livrable à part
entière : ce document est ce livrable.

---

## 1. Reconstitution historique — deux phases, pas une

**Correction factuelle sur la citation du cadrage amont.** `29-CONTEXT.md` (§Decisions, D-03) cite
« l'historique Phase 27, D-13 » comme source du mécanisme `--scope`. C'est **imprécis** : les
identifiants de décision (`D-01`, `D-02`, …) sont **scopés par fichier `*-CONTEXT.md`**, jamais
uniques globalement dans ce dépôt. Le `D-13` qui a réellement introduit `--scope` est celui de
`.planning/phases/VFDO-20-*/20-CONTEXT.md` (Phase 20) — le `D-13` de
`.planning/phases/VFDO-27-*/27-CONTEXT.md` (Phase 27) porte une décision sans rapport (« Tout
chiffre gravé porte sa méthode et se re-dérive au moment de l'écriture »,
`27-CONTEXT.md:155-156`). Un lecteur qui suivrait la citation « Phase 27, D-13 » à la lettre
atterrirait sur le mauvais artefact. C'est précisément la forme fautive que ce rapport n'emploie
pas.

Reconstitution précise, par commit (SHA courts, rejouables) :

| Étape | Commit | Date | Ce qui existait avant/après |
|---|---|---|---|
| Avant tout scope | `60576e9` (extraction team-kernel) | antérieur à Phase 20 | `dag.sh` ne porte **aucune** occurrence du mot `scope`. Rejeu : `git show 60576e9:plugin/conductor/scripts/dag.sh \| grep -c scope` → `0`. |
| **Phase 20, plan 20-02** | `d549b2d` | 2026-07-31 | Introduit `--scope` sur `dag.sh add` (D-13 de `20-CONTEXT.md`), force `review_regime=full` sur `reopen` d'un nœud revue/join (D-14), et ajoute `status --frozen` (table des périmètres gelés, D-15 §2). **Déclaration et lecture tolérante seulement — aucun calcul de disjonction à ce stade.** Rejeu : `git show d549b2d:plugin/conductor/scripts/dag.sh \| grep -c scope` → `11`. |
| **Phase 27** | `27abc07` (PR #35) | 2026-08-10 | Ajoute le champ `stages` sur `dag.sh ready` (câblage `partitionStages()` en sous-processus via `gsd-tools claude-orchestration emit-workflow`, ADR-069) **et** ferme une RCE réelle dans `resolve_gsd_tools_cmd()` (candidat cwd-relatif retiré, ADR-070). Rejeu : `git show 27abc07 --numstat -- plugin/conductor/scripts/dag.sh` → `106 insertions / 4 deletions`. |

**Forme de citation corrigée à employer partout où ce mécanisme est référencé** : « Phase 20
(déclaration du périmètre, D-13 de `20-CONTEXT.md`) puis Phase 27 (calcul de la disjonction via
`stages`, plus fermeture RCE, ADR-069/070) ». Jamais l'amalgame numéro-de-phase/numéro-de-décision
qui pointerait sur le `D-13` sans rapport de `27-CONTEXT.md`.

---

## 2. Inventaire exhaustif des consommateurs

| Consommateur | fichier:ligne | Nature | Citation |
|---|---|---|---|
| `dag.sh add` | `plugin/conductor/scripts/dag.sh:222-224` | Écriture seule — construction du nœud | `node["scope"] = scope  # affectation directe unique : CONSTRUCTION du noeud, jamais une lecture (P-02)` |
| `dag.sh ready` → `build_ready_manifest()` | `plugin/conductor/scripts/dag.sh:150-162` | Lecture tolérante — construit le manifeste envoyé au sous-processus amont | `"files_modified": n.get("scope", []),` — « Lecture tolerante a l'absence (P-02) : jamais d'acces direct a `scope`. » |
| `dag.sh ready` → `compute_stages()` | `plugin/conductor/scripts/dag.sh:164-196` | Câblage — sous-processus `gsd-tools claude-orchestration emit-workflow`, jamais de comparaison locale | « ne reimplemente AUCUNE comparaison de scope[] localement (ADR-069, Iron Law 2 revisee) » |
| `dag.sh status` → `frozen[]` | `plugin/conductor/scripts/dag.sh:285-306` | Lecture tolérante, dérive la table des « périmètres gelés » (tout nœud non-`done` à scope non vide) | « Lecture tolerante a l'absence (P-02) : node.get("scope", []) jamais un acces direct. … C'est la source unique et vivante de la table des fichiers geles » |
| `team-kernel.md`, table « Plan de bataille » | `plugin/conductor/references/team-kernel.md:19` | Doctrine — documente la frontière `ready` comme liste dispatchable en parallèle quand les périmètres sont disjoints | « la frontière `ready` est une **liste à dispatcher en parallèle** quand les périmètres sont disjoints » |
| `mission-flow.md`, Pattern B §stages | `plugin/dev-orchestrator/references/mission-flow.md:92-126` | Doctrine — documente le contrat complet (`ready`/`count` inchangés, `stages` additif, cascade de résolution, repli `null`/`[]`) | « la garantie ne vaut que ce que vaut le `scope[]` déclaré à la pose du nœud (`dag.sh add --scope=...`) » (l.105-106) |
| `mission-flow.md`, Pattern E §Pose du nœud | `plugin/dev-orchestrator/references/mission-flow.md:244-249` | Doctrine — le périmètre est déclaré à la pose, ce qui rend calculable le critère (b) (fichier partagé avec une mission parallèle en vol) de la gradation de revue | « Le périmètre (`--scope`) est déclaré à la pose : c'est ce qui rend calculable le critère (b) de la §3 ci-dessous » |
| `mission-contracts.md`, gabarit digest | `plugin/dev-orchestrator/references/mission-contracts.md:59` | Doctrine — chaque mandat de worker embarque le périmètre déclaré du nœud | « - Périmètre de fichiers du nœud : <déclaré au dag add> » |
| `team-kernel.md`, règle « Dispatch parallèle par défaut » | `plugin/conductor/references/team-kernel.md:123-125` | Doctrine — le jugement manuel du manager que `stages` vient soulager | « ≥ 2 nœuds `ready` à périmètres disjoints → un seul message, plusieurs Task. Périmètres douteux → **séquentiel** » |
| `check-agents.sh` (`isolation:` frontmatter) | `plugin/conductor/scripts/check-agents.sh:39,162,531` | **Objet distinct, à ne pas confondre** — `isolation: worktree` est une décision de dispatch séparée (issue #38), jamais dérivée de `scope[]` | `team-kernel.md:126-138` : « L'isolation est une décision de DISPATCH, jamais une propriété du worker » |
| `check-overlaps.sh` | `plugin/conductor/scripts/check-overlaps.sh:1-9` | **Objet distinct, piège de nommage documenté (D-08, Phase 27)** — routage de briques tierces (ADR-057), jamais disjonction de fichiers | En-tête du script : « Inventaire des recouvrements de déclenchement avec les briques TIERCES » |

**Motif de la confusion homonyme** : trois surfaces partagent un vocabulaire voisin (« scope »,
« isolation », « overlaps ») pour trois problèmes disjoints — le périmètre de fichiers d'un nœud
DAG, la décision de dispatch en worktree isolé, et le recouvrement de déclenchement entre briques
tierces. Un lecteur pressé qui grep `scope` sans lire la nature de chaque hit risque de mélanger
ces trois axes.

---

## 3. Couverture de la suite de tests (`test-dag.sh`, 501 lignes, T1-T33)

| Cas | Ce qu'il prouve |
|---|---|
| **T13** (`plugin/conductor/scripts/tests/test-dag.sh:167-181`) | `--scope` déclare et persiste le périmètre du nœud (2 entrées exactes, espaces rognés, entrée vide ignorée — même règle que `--deps`) |
| **T14, T22, T28** | Rétro-compatibilité : un DAG écrit par une version antérieure au champ `scope` (clé absente) ne fait jamais planter `ready`/`status`/`mark`/`reopen`/`tree` — lecture tolérante prouvée, pas seulement affirmée |
| **T20, T21** | `status --frozen` : un nœud non-`done` à scope non vide apparaît ; un nœud `done` ou à scope vide est exclu ; la clé `frozen` est toujours présente, même vide — jamais absente |
| **T24, T27.3** | Déterminisme : deux appels consécutifs produisent une sortie identique octet pour octet |
| **T25** | Deux nœuds `ready` déclarant le **même** chemin dans `scope[]` sortent dans **deux étages distincts** |
| **T26** | Deux nœuds `ready` à scope **disjoint** sortent dans **le même** étage |
| **T27.1-2** | En présence de `stages`, `ready`/`count` gardent exactement leurs valeurs d'avant ce mécanisme — non-régression du contrat de sortie |
| **T29** | CLI amont totalement introuvable (PATH + `GSD_TOOLS` + `CLAUDE_CONFIG_DIR` + `HOME` neutralisés) → `stages: null`, jamais un crash |
| **T30** | Frontière `ready` vide → `stages: []` sans lancer de sous-processus (preuve du court-circuit, pas seulement d'un résultat différent) |
| **T31** | CLI résolue mais qui échoue (`returncode != 0`) → `stages: null`, jamais `[]` (cible précisément `if result.returncode != 0: return None`) |
| **T32** | `node` absent mais `gsd-tools` (.cjs) résolu → `stages: null` via l'absence de `node` spécifiquement |
| **T33** | Non-régression de la RCE fermée (ADR-070) : un `gsd-tools.cjs` tracké au CWD n'est jamais résolu ni exécuté, même avec `node` disponible — preuve par deux signaux indépendants (fichier marqueur absent, contenu JSON piégé absent) |

**Verdict de couverture** : le mécanisme de disjonction (`stages`), le repli dégradé (`null` vs
`[]`), la rétro-compatibilité, et la fermeture de la RCE sont tous couverts par mutation ou par cas
explicite. Aucun trou visible dans `test-dag.sh` sur le périmètre `--scope` — c'est la suite la
plus exhaustive du dépôt sur un seul script (33 cas nommés). Exécution constatée cette session :
**99 PASS / 0 FAIL**, `rc=0`.

---

## 4. Verdict INTOUCHABLE / EXTENSIBLE SANS RISQUE

**INTOUCHABLE (ne jamais modifier)** :
- Le mécanisme de câblage `compute_stages()` lui-même — toute réimplémentation locale de la
  comparaison de `scope[]` est interdite par ADR-069 (Iron Law 2 révisée) et déjà gardée par T33.
- La cascade de résolution `resolve_gsd_tools_cmd()` — ne jamais réintroduire un candidat relatif
  au CWD ou à la racine du dépôt (`git rev-parse --show-toplevel`). C'est le 5e passage documenté
  du même motif de faille (ADR-070) ; un 6e serait une régression de sécurité connue, pas une
  découverte.
- La distinction sémantique `stages: null` (dégradé) vs `stages: []` (frontière vide) — toute la
  doctrine du manager en dépend (repli séquentiel sur `null`, pas sur `[]`).
- La forme de sortie `ready`/`count` — contrat octet-exact vérifié par T27.

**EXTENSIBLE SANS RISQUE** :
- Lire `dag.sh status --frozen` en pure consommation (aucune écriture) comme source de donnée pour
  n'importe quel script ou digest — c'est un champ déjà vivant, déjà testé (T20/T21), déjà
  déterministe (T24).
- Ajouter une nouvelle action/flag purement additive à `dag.sh` qui ne touche à aucune clé de
  sortie existante — le même patron de non-régression que `stages` lui-même (Phase 27 a prouvé que
  c'est faisable en gardant `ready`/`count` intacts).
- Étendre la doctrine textuelle de `team-kernel.md`/`mission-flow.md` — aucune surface de code.

---

## 5. Voie retenue pour G1

D-03 pose la voie « doctrine seule, manager rédige » comme repli sûr **si** un geste G1 exige de
toucher `dag.sh`. Cette investigation établit que **ce repli n'a même pas besoin d'être activé**.

Le « négatif du périmètre » que G1 doit produire — « ce que ce mandat ne doit PAS toucher » — se
compose intégralement de **deux champs déjà émis** par le socle :

1. Le périmètre déclaré du nœud lui-même, déjà threadé dans son digest de mission
   (`mission-contracts.md:59` : « Périmètre de fichiers du nœud : <déclaré au dag add> »).
2. Les périmètres gelés des **autres** nœuds actuellement en vol, déjà exposés en pure lecture par
   `dag.sh status --frozen` (§4 ci-dessus, EXTENSIBLE, déjà testé T20/T21, déterministe T24).

Le négatif se réduit donc à une opération de lecture — *(périmètres déclarés des autres nœuds
gelés) moins (périmètre déclaré de ce nœud)* — que le manager compose en rédigeant le digest, sans
qu'aucune ligne de `dag.sh` soit modifiée. La clause de repli de D-03 est non seulement sûre mais
**suffisante** : zéro ligne de `dag.sh` à toucher pour livrer G1.

**Conséquence pour le découpage des plans de la phase** : G1 se scinde proprement en deux
livrables indépendants et tous deux sans risque — (a) les tables statiques « Load / DO NOT Load »
dans les templates d'agents et les `CLAUDE.md` scaffoldés (aucune dépendance à `--scope`), et (b)
la ligne « NE charge PAS » du digest de mission, dérivée en doctrine des champs `dag.sh` déjà
émis (aucune dépendance à un nouveau code `dag.sh`).

**Clause de halte opposable** : si un futur besoin réclame un négatif *machine-vérifié* plutôt que
composé par le manager en doctrine, il doit suivre la même discipline de câblage que `stages`
lui-même — un sous-processus vers l'amont (`gsd-tools`), **jamais** une réimplémentation locale de
la comparaison de `scope[]` dans `dag.sh` (ADR-069, Iron Law 2 révisée). Ce n'est pas un
prérequis pour livrer G1 dans la Phase 29, et cela sort explicitement de son périmètre (D-01, D-02).

---

*Rapport consolidé depuis `29-RESEARCH.md` (§Investigation `dag.sh --scope`, l.341-448 et
§Common Pitfalls, Pitfall 1) — aucune investigation neuve menée ici.*
