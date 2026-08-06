# Décision — capability `claude_orchestration`

**Établi le :** 2026-08-06 · **Par :** exécuteur du plan `27-05` (tâche 3), sur le relevé du
checkpoint humain de la tâche 2, conduit en session principale.
**Convention de document :** celle de `24-COLLISIONS.md` — bandeau de statut, table de verdicts,
sections narratives.

> ## ⛔ STATUT DE CE DOCUMENT
>
> **Verdict : REFUS MOTIVÉ.** `claude_orchestration.enabled` repasse à `false` dans
> `.planning/config.json`. La capability n'est **pas** activée en l'état — pas parce que l'échelle
> de gates échoue (elle ne échoue pas : elle résout `workflow`, sans drapeau manuel, sur ce poste),
> mais parce que le **run réel diverge du chemin inline** au sens exact du critère FAIL n°2 de ce
> plan : aucun commit de worker, aucun `SUMMARY.md`, aucun merge vers l'arbre principal, deux
> worktrees laissés résiduels après la fin du run.
>
> **Ce que ce refus ne remet pas en cause :** la décision de persistance de
> `GSD_AGENT_SDK_VERSION` (option 3, installation réelle dans `~/.claude`) reste **acquise et
> opérante au niveau machine** — elle n'est pas liée au verdict de la capability et n'est **pas**
> désinstallée par ce document. Elle a d'ailleurs fait la preuve de sa valeur : c'est elle qui a
> permis à `resolve-wave-dispatch` de résoudre `workflow` sans aucun drapeau manuel, condition
> nécessaire pour même *observer* le run qui a produit le refus.

## Table de verdicts

| Critère | Source | Observé | Conclusion |
|---|---|---|---|
| PASS n°1 — échelle des 7 gates résout `workflow` avec SDK réellement installé | plan `27-05`, §Critères | `resolve-wave-dispatch` sans `--agent-sdk-version` → `{"backend":"workflow","reason":"workflow_backend_active"}` | **Satisfait** |
| PASS n°2 — run réel produit les mêmes artefacts que l'inline, aucune collision, sans intervention humaine | plan `27-05`, §Critères | fichiers écrits sans collision, run sans intervention humaine — **mais** aucun commit de worker, aucun `SUMMARY.md`, aucun merge | **Non satisfait** |
| PASS n°3 — Décision A ne produit pas de silence dangereux | plan `27-05`, §Critères | issue n°3 : question remontée en rapport, 0 écriture | **Satisfait** |
| FAIL n°1 — l'échelle ne résout jamais `workflow` | plan `27-05`, §Critères | `workflow` résolu dès l'observation 1 | **Non constitué** |
| **FAIL n°2 — le run réel diverge du chemin inline (artefacts différents, erreur non récupérée, worktree non nettoyé)** | plan `27-05`, §Critères | **artefacts différents (pas de commit, pas de SUMMARY, pas de merge) ET worktrees non nettoyés** — deux des trois formes citées par le critère, simultanément | **CONSTITUÉ** |
| FAIL n°3 — Décision A révèle un silence dangereux | plan `27-05`, §Critères | aucun silence : question visible dans le journal et dans le retour | **Non constitué** |
| PASS partiel (échelle franchie, Décision A incertaine) | plan `27-05`, §Critères | échelle franchie, **mais Décision A n'est pas incertaine** — elle est confirmée sûre (PASS n°3) | **Ne s'applique pas à ce cas** |

**Lecture du tableau, sans renégociation des critères.** Deux des trois conditions PASS sont
satisfaites (n°1 et n°3). Mais les critères FAIL sont écrits comme une **disjonction** : « n'importe
laquelle de ces conditions » suffit. FAIL n°2 est constitué, seul, indépendamment du sort de PASS n°1
et n°3 — la disjonction ne s'annule pas parce que d'autres critères sont bons. Le cas « PASS partiel »
ne s'applique pas non plus : il suppose une Décision A *incertaine*, or l'observation 2 l'a tranchée
sans ambiguïté (issue n°3, sûre). Ce n'est donc ni un PASS, ni un PASS partiel : c'est un **FAIL net**
sur le critère n°2, et le verdict en découle mécaniquement, sans marge d'interprétation.

---

## 1. Critères PASS/FAIL — recopiés depuis le plan `27-05`, écrits avant toute observation

Ces critères ont été figés dans le plan **avant** que le run de la tâche 2 n'ait lieu — c'est ce qui
les rend opposables : aucune reformulation n'a eu lieu après coup pour les faire coller au résultat.

**PASS — les trois conditions, toutes vérifiées :**

1. L'échelle des 7 gates résout `backend: "workflow"` avec une version de SDK **réellement
   installée** et lue dans le `package.json` du paquet — jamais un drapeau inventé.
2. Le run réel trivial (étape 2) produit les mêmes artefacts que le chemin inline : les deux fichiers
   attendus existent, chacun dans le commit de son propre worker, aucune collision, run terminé sans
   intervention humaine.
3. La sous-expérience de la Décision A confirme que l'absence d'entrée utilisateur en cours de run
   **ne produit pas de silence dangereux** : soit le run échoue explicitement, soit il remonte le
   besoin dans son rapport de fin de run. Jamais un « faux terminé » qui aurait ignoré la demande.

**FAIL — n'importe laquelle de ces conditions :**

1. L'échelle ne résout jamais `workflow`, même avec un SDK installé et la capability activée
   (blocage structurel du poste ou du runtime). Ce critère couvre nommément le cas où aucune option
   de persistance de `GSD_AGENT_SDK_VERSION` n'est jugée acceptable pour ce poste.
2. Le run réel diverge du chemin inline : artefacts différents, erreur non récupérée, worktree non
   nettoyé.
3. La sous-expérience de la Décision A révèle un silence dangereux — le run se termine en succès
   alors que la question posée par l'agent n'a été traitée nulle part, ni dans le rapport, ni
   ailleurs.

**Sur FAIL** : le livrable se conclut par un refus motivé et écrit, sur le patron des capacités
dormantes refusées en Phase 24 (GSDA-06, GSDA-08, GSDA-10), avec son déclencheur objectif de reprise.

**Sur PASS partiel** (échelle franchie mais Décision A incertaine) : l'activation reste possible
uniquement si la décision écrite pose le repli « un étage = un workflow » en contrainte
opérationnelle du manager.

---

## 2. Provenance de la version du SDK

- **Commande d'installation (tâche 1, spike jetable) :** `npm --prefix <répertoire jetable> install
  --silent --no-audit --no-fund @anthropic-ai/claude-agent-sdk`
- **Chemin lu :** `package.json` du paquet posé sous `<jetable>/node_modules/@anthropic-ai/claude-agent-sdk/`
- **Valeur obtenue :** `0.3.223`
- **Date :** 2026-08-06

**La limite qui subsiste, écrite telle quelle.** La correspondance entre la version npm du SDK
(`@anthropic-ai/claude-agent-sdk`) et le niveau de l'outil Workflow réellement embarqué dans le
binaire `claude` **n'est garantie par personne** — la recherche du plan `27-05` a établi sur pièce que
les schémas de version du CLI et du SDK sont indépendants. Franchir les gates 5 et 6 (version semver
valide, plancher atteint) est donc un prérequis **nécessaire mais non suffisant** : ce n'est qu'une
preuve de provenance, pas une preuve de fonctionnement. **Seul le run réel fait preuve** — et c'est
précisément ce run réel qui a produit le refus consigné ici, malgré un franchissement de gates
irréprochable.

---

## 2bis. Décision de persistance de `GSD_AGENT_SDK_VERSION` au runtime (B1)

**Rendue par Samuel au checkpoint de la tâche 2 (AskUserQuestion en session, 2026-08-06) : option 3**
— installation réelle et persistante du paquet sur la chaîne de résolution `__dirname` de
`gsd-core`, celle qu'emprunte `resolveInstalledAgentSdkVersion` en production.

- **Geste appliqué :** `npm --prefix ~/.claude install --no-audit --no-fund
  @anthropic-ai/claude-agent-sdk`.
- **`~/.claude/package.json`** existait déjà (`{"type":"commonjs"}`, posé le 2026-08-04) ; il porte
  désormais `"dependencies": {"@anthropic-ai/claude-agent-sdk": "^0.3.223"}`.
- **Version installée**, lue dans `~/.claude/node_modules/@anthropic-ai/claude-agent-sdk/package.json` :
  `0.3.223` — identique à la version relevée par le spike jetable de la tâche 1, même jour, même
  dist-tag.
- **Portée :** tout le poste, tous les labs qui invoquent `~/.claude/gsd-core` — pas seulement ce
  dépôt. Aucune valeur épinglée : la version résolue reste toujours celle réellement installée
  (D-09 respecté). Maintenance : `npm update` occasionnel dans `~/.claude`, hors du contrôle git de
  ce dépôt.
- **Motif du choix, vs les deux autres options** (bloc `env` d'un `settings.json`, export dans le
  profil shell) : les deux autres épinglent une valeur à la main, avec dérive silencieuse si le SDK
  est republié sans que le gate 5 ne s'en aperçoive. L'option 3 est la seule où le gate 5 lit un
  **fait** (un paquet réellement présent sur la chaîne de résolution), pas une **déclaration**.

**Vérifié comme la seule chose qui fasse effectivement franchir le gate 5 sur ce poste** :
`resolve-wave-dispatch` — le chemin **réellement emprunté en production** par `execute-phase.md`,
distinct du chemin de la tâche 1 qui passait `--agent-sdk-version` à la main — invoqué **sans**
drapeau manuel, avec le manifeste `27-mesure/waves-toy.json` :

```json
{"backend": "workflow", "reason": "workflow_backend_active"}
```

C'est ce verdict-là, obtenu sans drapeau, qui dit ce qu'un run de production ferait aujourd'hui — pas
celui de la tâche 1. La persistance option 3 est donc **prouvée opérante**, indépendamment du verdict
de la capability rendu plus bas : elle reste acquise et n'est **pas** désinstallée par ce document.

---

## 3. Verdict de l'échelle des 7 gates — sortie brute

| # | Condition | Résultat sur ce poste |
|---|---|---|
| 1 | capability activée | vrai (`enabled: true` posé par la tâche 1) |
| 2 | runtime `claude` | vrai |
| 3 | `execution_backend` ≠ `inline` | vrai (`"auto"`) |
| 4 | descripteur d'hôte porte `dispatch.nested` et `dispatch.background` | vrai (proxy de présence, pas une preuve de fonctionnement) |
| 5 | version du SDK est un semver valide | vrai — `0.3.223`, résolue via la persistance option 3 sur la chaîne `__dirname` |
| 6 | version du SDK atteint le plancher | vrai |
| 7 | `execution_backend` vaut `auto` ou `workflow` | vrai |

**Verdict brut, sans drapeau manuel :**

```json
{"backend": "workflow", "reason": "workflow_backend_active"}
```

Aucun gate n'échoue. L'échelle est intégralement franchie, sur le chemin réel de production. Ce
franchissement est un prérequis **nécessaire mais non suffisant** — voir §2 : c'est le run réel, en
§4, qui apporte le fait disqualifiant.

---

## 4. Les trois observations du run — transcrites telles que rendues au checkpoint

### Observation « run réel » (critère PASS n°2 / FAIL n°2)

Run du script émis avec l'outil Workflow réel de la session (run ID `wf_fea42b76-3e2`) : terminé en
**32 s**, 2 agents parallèles, 0 erreur, **sans intervention humaine**.

Ce qui correspond au chemin inline :
- Les deux fichiers `toy-a.txt` / `toy-b.txt` ont été écrits, à l'octet attendu, sans collision
  (horodatages UTC `12:21:48Z` et `12:22:03Z`, recouvrement partiel).

Ce qui **diverge** du chemin inline — constituant le critère FAIL n°2 :
- **Aucun commit de worker** : les fichiers sont restés `untracked` (`??`) dans chaque worktree. Le
  commentaire du script émis promet « commits land there and are merged by the orchestrator exactly
  as in inline wave dispatch » — rien de tel ne s'est produit : pas de `SUMMARY.md`, pas de commit,
  **pas de merge vers l'arbre principal** (le répertoire `scratch/` n'existe nulle part côté arbre
  principal).
- **Worktrees non nettoyés** : les deux worktrees (`.claude/worktrees/wf_fea42b76-3e2-1` et `-2`) sont
  restés résiduels après la fin du run. Nettoyage manuel requis, effectué ensuite par l'orchestrateur
  de session (`git worktree remove --force` + `branch -D` + `prune`), après consignation de leur
  contenu.

**Cause structurelle établie** (pas seulement le symptôme) : le brief d'une ligne du corpus jouet
n'embarque pas le protocole d'exécution GSD (`execute-plan.md`) — `agentType: "gsd-executor"` seul ne
suffit pas à produire commit + `SUMMARY.md`. Et l'outil Workflow (`isolation: "worktree"`) n'auto-
nettoie que les worktrees **inchangés** : un fichier écrit et non commité rend le worktree « changé »,
donc conservé, et aucun orchestrateur ne le merge automatiquement.

**Note de corpus, hors verdict :** les briefs de `waves-toy.json` abrègent le chemin de phase en
`VFDO-27-...` (littéral, tronqué) tandis que `files_modified` porte le chemin complet — un agent a dû
faire un `ls .planning/phases/` pour résoudre le nom exact. Résolu sans y faire obstacle, mais c'est
une ambiguïté du corpus à noter pour un futur spike.

**Chiffres bruts (pour référence, hors verdict) :** run trivial à 2 plans parallèles, 32,4 s
wall-clock, 103 938 tokens sous-agents, 9 tool uses.

### Observation « Décision A » (critère PASS n°3 / FAIL n°3)

Manifeste à un seul plan (`waves-decision-a.json`, scratchpad de session), dont le brief exige de
poser une question à l'utilisateur avant d'écrire le fichier. Run `wf_5ad43149-45e` : 12,6 s, 1 agent,
0 tool use.

**Verdict : issue n°3 — la sûre.** L'agent n'a **rien** écrit (0 tool use), n'a **pas** bloqué, et a
retourné sa question comme résultat final, à l'octet : « Quel horodatage veux-tu dans le fichier :
UTC ou heure de Paris ? / Je n'écrirai `toy-q.txt` qu'après ta réponse. » La question est visible dans
le journal du run et dans le retour à l'orchestrateur. **Pas de silence dangereux** — le critère FAIL
n°3 n'est pas constitué.

**Nuance à écrire, malgré ce PASS partiel local :** le run global se conclut « completed » sans signal
distinctif indiquant qu'un agent est resté en attente d'une réponse — c'est à l'orchestrateur (humain
ou manager) de **lire** les résultats pour s'en rendre compte, rien ne le pousse automatiquement.
D'où la confirmation, sous run réel et non plus par hypothèse, que la contrainte opérationnelle D-02
(« un étage = un workflow », arbitrage humain **entre** les workflows) reste nécessaire — pas
seulement recommandée.

**Corrélat utile :** le worktree de ce run (aucune écriture) a été auto-nettoyé — confirme en creux
que l'auto-nettoyage ne couvre que les worktrees **inchangés**, la cause exacte des résidus du run
réel ci-dessus.

### Observation « repli fail-closed » (Q4c)

Re-testé **après** manipulation de la config, pas seulement supposé :

- `claude_orchestration.enabled` basculé à `false` → `detect-backend` :
  `{"available": false, "backend": "inline", "reason": "capability_disabled"}` ;
  `resolve-wave-dispatch` (chemin réel) : `{"backend": "inline", "reason": "capability_disabled"}`.
- Clé restaurée dans son état de départ : `{"enabled": true, "execution_backend": "auto"}`
  — `git diff` vide vs le commit `bb83a94` au moment du re-test.

Le repli vers `inline` est **identique, à l'octet près, au comportement d'aujourd'hui.** Aucun état
résiduel constaté après manipulation.

---

## 5. Les quatre relevés de sondes (A1, A2, A4, A5)

Ouvertes par `27-ISOLATION-PORTEE.md` (plan `27-03`) — ce document n'y écrit pas, il renvoie et
consigne les observations rendues par le run réel de la tâche 2, qui en est la **première occasion**
d'observation réelle.

- **A1** (syntaxe `.worktreeinclude`) : `.claude/agent-memory/` **présent** dans les deux worktrees du
  run réel (`vf-auditer/`, `vf-coder/`, `vf-dev-manager/`, …). La syntaxe actuelle fonctionne comme
  prévu.
- **A2** (chemin réel du dossier de worktree) : `.claude/worktrees/wf_<runId>-<n>` (ex.
  `wf_fea42b76-3e2-1`), branche `worktree-wf_<runId>-<n>`. **Hors du namespace `agent-*` /
  `worktree-agent-*`** attendu par les guards worktree-branch-check du chemin inline.
- **A4** (`GSD_WORKSTREAM`) : `echo "$GSD_WORKSTREAM"` depuis le worktree isolé rend une valeur
  **vide**.
- **A5** (`docs/reference/`) : **échec de lecture** depuis le worktree. Cause établie, pas seulement
  constatée : `docs/reference/` est **untracked** (0 fichier dans `git ls-files`) — git worktree ne
  matérialise que le contenu tracké plus `.worktreeinclude`, et `docs/reference/` n'y figure pas.

---

## 6. Verdict

**REFUS MOTIVÉ.** Le critère FAIL n°2 (« le run réel diverge du chemin inline : artefacts différents,
erreur non récupérée, worktree non nettoyé ») est constitué sur deux de ses trois formes
simultanément — artefacts différents (aucun commit de worker, aucun `SUMMARY.md`, aucun merge vers
l'arbre principal) et worktree non nettoyé — malgré un franchissement irréprochable de l'échelle des
7 gates (PASS n°1) et une Décision A confirmée sûre (PASS n°3). Les critères FAIL sont une
disjonction : une seule condition suffit, et elle est ici doublement constituée. Ce n'est pas un « PASS
partiel » — ce cas suppose une Décision A *incertaine*, or elle a été tranchée sans ambiguïté par
l'observation 2.

**Ce que ce refus établit, et ce qu'il n'établit pas :**
- Il établit que l'outil Workflow, **utilisé tel quel avec un brief d'une ligne**, ne produit pas le
  contrat que le chemin inline garantit (commit par worker, mergé, aucun résidu).
- Il n'établit **rien** sur l'outil Workflow lui-même en tant que mécanisme d'isolation et de
  dispatch : l'isolation a fonctionné parfaitement (0 collision), la Décision A a montré un
  comportement sûr, et l'échelle de gates a été franchie sur le chemin réel de production sans aucune
  triche. La cause du refus est **localisée** : l'absence, dans le brief émis par ce spike, du
  protocole d'exécution GSD complet (`execute-plan.md`) et l'absence d'un mécanisme de merge/nettoyage
  côté orchestrateur pour les worktrees changés.

### Déclencheur objectif de reprise

Sur le patron des capacités dormantes refusées en Phase 24 (GSDA-06, GSDA-08, GSDA-10) : le refus ne
porte pas de date de réexamen, il porte une **condition factuelle**. Rouvrir `claude_orchestration`
**ssi**, dans cet ordre, les deux faits suivants sont établis par un nouveau run réel — pas supposés :

1. **Le brief émis pour un plan dispatché via l'outil Workflow embarque le protocole d'exécution GSD
   complet** (a minima l'équivalent de `execute-plan.md` : commit atomique par tâche, `SUMMARY.md`
   écrit, protocole de commit respecté) — pas seulement `agentType: "gsd-executor"` sur un brief d'une
   ligne, tel qu'il l'était dans ce spike.
2. **Un mécanisme de merge et de nettoyage existe côté orchestrateur** pour les worktrees du run
   Workflow qui contiennent des changements (commités ou non) — pas seulement l'auto-nettoyage natif
   de l'outil, qui ne couvre que les worktrees inchangés (confirmé en creux par l'observation
   « Décision A » de ce document).

Tant que ces deux faits ne sont pas établis sous un run réel, la divergence observée au §4 se
reproduira à l'identique : c'est un défaut structurel du couplage (brief jouet + outil Workflow), pas
un aléa d'exécution. **La décision de persistance de `GSD_AGENT_SDK_VERSION` (option 3, §2bis) reste
acquise** — elle n'est pas remise en cause par ce refus et n'a pas besoin d'être rejouée à la reprise.

---

## Ce que ce document ne fait pas

- Il ne touche ni `27-MESURE-GAIN.md` (plans `27-04`/`27-06`), ni `27-ISOLATION-PORTEE.md` (plan
  `27-03`), ni `.planning/STATE.md` — la mise à jour de l'état de projet appartient au manager de
  mission à la clôture, pas à ce plan.
- Il ne désinstalle rien : la persistance `GSD_AGENT_SDK_VERSION` (option 3, `~/.claude`) reste posée
  et opérante au niveau machine.
- Il ne referme pas la capability à titre définitif : le déclencheur de reprise ci-dessus est
  objectif, pas une clôture.

## Références

`27-05-PLAN.md` (critères figés, échelle de gates) · `27-ISOLATION-PORTEE.md` (A1/A2/A4/A5 ouvertes) ·
`24-COLLISIONS.md` (convention de document, patron GSDA-06/08/10) · `27-03-SUMMARY.md`,
`27-04-SUMMARY.md` (contexte de phase).
