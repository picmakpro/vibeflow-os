# Mission — Phase 23 « Couplage explicite au moteur GSD », reprise après pause

- **Date** : 2026-08-02
- **Worktree** : `../vibeflow-os-p23`, branche `feat/phase-23-couplage-gsd`
- **Base** : `0c50d6b` (handoff de la session précédente)
- **Driver lock** : `mission-phase23-couplage-gsd`, acquis puis récupéré une fois (périmé pendant un
  dispatch de 30 min), relâché à la clôture.
- **DAG** : `.planning/MISSION-23.dag.json` — repris tel quel, jamais reconstruit.

## Plan de bataille

Reprise au nœud `revue-01`, seul nœud `ready` du DAG hérité (17 nœuds, `exec-01` done, 15 blocked en
cascade). Aucun pipelining N/N+1 : le DAG est strictement sériel (chaque `exec-NN` dépend de
`revue-(NN-1)`), et les workers commitent dans un worktree unique — deux exécutants concurrents sur
le même index git ne sont pas un périmètre disjoint. Décision consignée : séquentiel assumé.

## Ce qui s'est passé

`revue-01` n'a jamais rendu PASS. Trois revues en régime plein, trois tours de comblement.

| Tour | Verdict | Ce que la revue a démontré |
|---|---|---|
| Revue 1 | `gaps_found` — 4 bloquants | Les 3 gates ajoutés par 23-01 ne verrouillent pas les décisions qu'ils annoncent. 3 mutations sémantiques laissent la suite à 0 KO. Le gate D-02 **bénit en fixture** la ligne exacte qui annule D-02. |
| Revue 2 | `gaps_found` — 2 bloquants | Portée passée de « fichier » à « bloc », mais la co-présence subsiste : une doctrine disant l'**inverse exact** de D-01 → `87 OK / 0 KO`. `T26 A` certifie « énumération close » sur un contrat listant ce qu'il interdit. Découvre une **régression que mon propre mandat avait causée** (verrou de nom `plan_id` supprimé). |
| Revue 3 | `gaps_found` — 1 bloquant | La sonde stricte existe et fonctionne, mais **n'est pas atteinte** sur 2 cibles sur 3 — dont `mission-contracts.md`, qui porte l'énoncé faisant autorité de D-01. Cause : le compteur ne reconnaît que la graphie backtickée nue, pas la graphie JSON. |

Le tour 4 a fermé le bloquant (deux formes rhétoriques reconnues : énumération `étiquette → mapping`
et implication `prémisse ⇒ conséquent` ; `rc=3` = KO explicite, plus aucun repli permissif) et
remplacé la liste noire de `T26 A` par une égalité d'ensemble.

## Livré

10 commits au-dessus de `0c50d6b`, **2 fichiers** touchés :
`scripts/tests/test-dev-orchestrator.sh` (+~640/−160) et `agents/vf-dev-manager.md` (12/12, rewrap à
coût nul, 244/250 lignes inchangé — marge ADR-029 intacte).

- `17086d2` M-4 — second motif de D-01 (« précondition non satisfaite ») réintroduit inline
- `a037332` T24 — co-occurrence du mapping
- `0e66c78` T25/T26 — assertions bornées au bloc, ensemble mesuré, balayage résolu
- `3df9f97` splitter sensible à l'indentation + isolation du segment de statut
- `a61c7b3` T24 volet D — mutation de **relation**, fixture licite, commentaire honnête
- `6f24e3d` T25 — deux classes de **faux rouges** sur rédaction légitime éliminées
- `1a2bdc0` T26 A/A′ — garde aligné sur la coupe, coupe no-op = échec, ancrage D-03 restauré
- `b45aaee` mineurs — trap EXIT, `T2B_STUB` tracké
- `331f10a` **sonde stricte du mapping D-01 sur les trois cibles T24**
- `5d5fe9f` **ensemble clos, et non liste noire**, pour le minimum de reprise

**Gates** (vérifiés par le manager, pas seulement rapportés) : `test-dev-orchestrator.sh` →
**87 OK / 0 KO / 0 SKIP**, déterministe · `check-agents.sh --agents-dir=plugin/dev-orchestrator/agents`
→ ✓, 7 warnings préexistants · `bash -n` OK · les **87 libellés d'`ok` sont identiques** à ceux de la
base : aucune assertion retirée en douce, seuls les internes ont été durcis.

Mutations désormais **rouges** (chacune conservant tous les tokens) : D-01 inversé dans les trois
fichiers · relation pure par échange d'étiquettes · contrat à 6 sous-champs avec et sans la borne en
gras · rename des 4 noms D-03 · forme interdite sur sous-puce imbriquée (2 niveaux) · cibles vides ·
champ hors ensemble clos. Rédactions légitimes restées **vertes** : négation rédigée · bloc
« Planification amont » · `` `human_needed` `` et `` `statut` `` en prose · reformulation de D-01 ·
forme à contraste explicite.

## État du DAG à la clôture

`exec-01` **done** · `revue-01` **ready, non re-dispatché** (budget de boucle atteint : 3 revues +
4 comblements sur un seul nœud) · 15 nœuds **blocked**. Reprenable en l'état.

## Ce qui remonte à l'humain

Sept arbitrages. Aucun n'a été tranché seul — quatre touchent des fichiers de doctrine délibérément
**gelés** pendant toute la mission pour cette raison.

### Doctrine (bloquent le fond de la Lacune 6)

1. **D-02 est inerte — le désarmement crée la condition de son propre ré-armement.** Amont,
   `chain.md:39-42` ré-arme `workflow._auto_chain_active` si le chain flag est présent **et**
   `AUTO_MODE` faux. Le geste 5 met le flag à faux → satisfait la précondition ; puis `vf-coder.md:27`
   invoque le cadrage en mode non-interactif (`--auto`) → le flag repart à `true` pour toute la
   mission. Et le gate T25 écrit pour fermer ce risque déclare cette ligne **licite** et l'immortalise
   en fixture : il est anti-corrélé au risque qu'il annonce couvrir. Options : re-désarmer après
   chaque retour de worker · faire porter le désarmement par `vf-coder` après son cadrage · retirer
   `--auto` au profit de `--assumptions`.
2. **`workflow.auto_advance` n'est jamais désarmé.** Second déclencheur de la règle 5 amont
   (`checkpoints.md:11`), absent de tout `plugin/`. Correctif mécanique, mais il coûte des lignes sur
   un agent à 244/250 et dépend de la forme retenue en (1).
3. **Le minimum de reprise ne transporte pas la réponse humaine.** Les 4 sous-champs décrivent tous
   **la question** ; l'amont exige `{user_response}` et la table des tâches faites — que le contrat
   interdit explicitement. Le manager est instruit de redispatcher « avec l'attendu », c'est-à-dire
   avec la question qu'on vient de reposer : le worker neuf retombe sur le même checkpoint et rend
   `human_needed`. **Ping-pong sur un gate `blocking-human`.**
4. **Geler le nœud ou poser la question ?** Deux clauses consécutives du contrôle de flux, la seconde
   sans qualificatif de mode, alors qu'en mode autonome l'utilisateur est par définition absent. Un
   agent peut résoudre la tension dans le mauvais sens — répondre lui-même à une attente humaine.

### Couverture de test (le gate est vert, la question est son périmètre)

5. **`rc=3` contraint la forme rédactionnelle.** Une réécriture en prose sémantiquement correcte du
   bloc Verdict rougit. Le message est honnête (« non vérifiable », pas « doctrine fausse »), mais le
   gate impose la forme énumérative aux réécritures à venir — or les points 1 à 4 vont précisément
   réécrire ces fichiers.
6. **Porosité de T25 assumée.** Une prescription rédigée avec une négation dans la même clause
   échappe. Coût chiffré : ajouter `,` aux séparateurs ferme le trou et préserve les 6 fixtures, au
   prix d'un seul nouveau faux rouge (négation avec incise). Écart orienté vers le faux vert.
7. **Déclassement de T26 A′.** Le worker déclare « aucun champ inventé côté worker » non gateable ;
   le reviewer estime la formulation trop large — les positions de **clé JSON** offrent une surface
   réelle, sans le faux rouge de prose, à coupler à un garde « ≥1 clé mesurée ou renvoi explicite ».

## Next step

Trancher les points 1 à 4 (ils commandent la suite : la Lacune 3 / plan 23-03 ne peut pas être écrite
sans savoir ce qu'un `--auto` auto-approuve), puis relancer `revue-01` sur le diff consolidé avant
d'ouvrir `exec-02`.
