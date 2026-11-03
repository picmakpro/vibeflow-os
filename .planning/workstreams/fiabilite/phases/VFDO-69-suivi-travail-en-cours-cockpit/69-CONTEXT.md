# Phase 69: Suivi du travail en cours dans le cockpit - Context

**Gathered:** 2026-11-03
**Status:** Cadrée — non planifiée

Inscription et cadrage documentaires (aucun code). Entrée unique :
`.planning/notes/2026-11-03-cockpit-progression-en-cours.md` (note de conception, copiée telle quelle).
Décision source : option A de cette note, **arbitrage Samuel, AskUserQuestion session principale,
2026-11-03**, « à implémenter dans la phase qui suit la 67 ». Création de la phase demandée par Samuel
en session principale, 2026-11-03. Numéro 69 posé à la main (le moteur propose un mauvais numéro sur ce
dépôt). Jalon `vibeflow-v2.0`, compartiment `fiabilite`.

**Exigences :** CKPT-13 à CKPT-18 (suite de la famille de la Phase 67, libres le 2026-11-03), inscrites dans
`REQUIREMENTS.md` du compartiment et dans la ligne `Requirements` de la Phase 69 du ROADMAP.

<domain>
## Phase Boundary

La carte Projet du cockpit (`plugin/cockpit/scripts/vf-cockpit-project.mjs`) affiche aujourd'hui, pour le
jalon `vibeflow-v2.0`, « 0/2 phases · 0 % · à faire », et pour la Phase 67 « à faire · 11/7 plans · 0/12
exigences », alors que ses 7 plans sont exécutés et la PR #187 ouverte. La phase calcule dans la lib de
lecture (`readPlanning`, `vf-cockpit-planning.mjs`, futur socle de `vf-signal`, Phase 68) un état
d'avancement dérivé de traces locales, et retire la seule règle fausse.

**Hors périmètre :** option B ; toute lecture réseau ; release (geste humain).

</domain>

<decisions>
## Implementation Decisions

Registre de la phase : identifiants préfixés `P69-D-NN` (convention CLAUDE.md, ADR-075).

### Constat — causes mesurées dans le code (note § 1, branche `feat/v2-cockpit`)

- **C1** Phase 67 « à faire » : `phaseStatus` (`vf-cockpit-project.mjs:36`) ne connaît que 3 cas — case de
  ROADMAP cochée → fait ; `ph.n === curPhase` (`current_phase` du STATE) → en cours ; sinon → à faire.
  Le STATE pointe sur la 62 : plans et mission ne sont jamais lus pour le statut.
- **C2** « 11/7 plans » : `sums` (`:63`) compte tous les `*-SUMMARY.md`, dont les 4 `67-FIX-{A..D}-SUMMARY.md`
  (correctifs de mission, sans PLAN) : 7 + 4 = 11. Ce ne sont pas des nœuds de DAG.
- **C3** Jalon à 0 % : le pied (`:56`) ne compte que les phases à case cochée ; le statut du jalon (`:47`)
  vient de l'icône (`📋` → à faire) ou d'une phase close.
- **C4** Mission non rattachée : rattachement seulement si le DAG s'appelle `MISSION-<n>` (`:90`) ; celui de
  la 67, `2026-11-01-v2-cockpit.dag.json`, tombe dans « Missions hors phase ».
- **C5** Exigences 0/12 : cochées à la clôture de la phase seulement — voulu, seule vérité d'exigence. Rien
  à changer.

### Arbitrage de Samuel (AskUserQuestion session principale, 2026-11-03)

- **P69-D-01 (option A retenue, B écartée).** Statut de phase dérivé dans la lib de lecture, objet versionné,
  rien d'autre. Coût estimé : une vingtaine de lignes, affichage existant réutilisé, 4 cas de test.

### Règles de l'option A (note § 2)

- **P69-D-02 (objet `avancement`).** `readPlanning` expose par phase
  `{ "version": 1, "etat": …, "plans": {"faits","total"}, "correctifs": N, "mission": {"nom","etat"}, "reste": […] }`
  (CKPT-13). Il sera consommé par `vf-signal` (Phase 68).
- **P69-D-03 (quatre états, chacun avec sa preuve locale).** `a-faire` : aucun SUMMARY de plan ;
  `en-cours` : au moins un plan fait, ou mission rattachée avec un nœud `running` ; `a-recetter` : tous les
  plans faits, phase non cochée ; `fait` : case de ROADMAP cochée (CKPT-13). « À recetter » se déduit de
  « tous les plans faits et phase non close », jamais de « PR ouverte ».
- **P69-D-04 (décompte des plans, C2).** Un plan est fait s'il a un `*-PLAN.md` **et** son
  `*-SUMMARY.md`. Les SUMMARY sans PLAN forment une ligne à part, « 4 correctifs » (CKPT-14).
- **P69-D-05 (rattachement des missions, C4).** Dans l'ordre : (1) champ `phase` du DAG s'il existe,
  (2) nom `MISSION-<n>`, (3) DAG situé dans le dossier de la phase. Le cas de la 67 se règle par (1) : une
  ligne `"phase": "67"` dans son DAG (CKPT-15). Poser cette ligne dans le DAG de la 67 est un geste de
  mission, hors de cette phase documentaire.
- **P69-D-06 (jalon et pied).** Le jalon est `en-cours` dès qu'une de ses phases est `en-cours` ou
  `a-recetter`, quel que soit le STATE. Pied : « 0 clos · 1 à recetter · 1 à faire · 0 % ». Le pourcentage
  reste strict (phases closes seulement), jamais pondéré (CKPT-16).
- **P69-D-07 (`reste`, traces locales seulement).** Recette humaine : un `*-RECETTE-HUMAINE.md` dont le
  statut n'est pas « FAITE » ; vérification : pas de `*-VERIFICATION.md` ; clôture : case de ROADMAP non
  cochée. CI, merge et release ne sont **pas** affichés ; au mieux la release se lira depuis un tag local,
  « à voir plus tard » (CKPT-17).
- **P69-D-08 (retrait, un ajout = un retrait).** On supprime la règle `ph.n === curPhase` : le STATE ne
  pilote plus le statut d'une phase sur la carte, c'est la seule source qui ment ici (CKPT-18).

### Limite de fond

- **P69-D-09 (aucune lecture réseau).** Le cockpit ne fait aucun appel réseau (recette 67, point 5 ;
  P67-D-02). L'état d'une PR, de la CI ou d'un merge n'est donc **pas lisible** : « PR ouverte » ne peut
  venir que d'une trace locale, et la carte ne prétend jamais savoir ce qu'elle ne peut pas lire.

### Quatre témoins rouges (fixtures de lab, un par règle, joués avant le code)

| # | Fixture | Attendu | Aujourd'hui (rouge) |
|---|---|---|---|
| a | 7 PLAN, 7 SUMMARY et 4 SUMMARY de correctif | `7/7 plans · 4 correctifs` | 11/7 |
| b | STATE sur une autre phase, plans faits | `a-recetter` | à faire |
| c | DAG avec `phase: 67` | rattaché à la 67 | hors phase |
| d | Jalon `📋` avec une phase `a-recetter` | jalon `en-cours` | à faire |

Un témoin « décompte faussé par un nœud DAG » serait vert dès aujourd'hui et ne prouverait rien : le bon
témoin du décompte est un SUMMARY sans PLAN (note § 3 bis). Le retrait de la règle STATE (CKPT-18) se prouve
par le témoin (b) plus un test qui rougit si `curPhase` redevient une source de statut.

### Points écartés (option B, note § 3)

- Pourcentage de jalon pondéré : précision fausse (un plan n'est pas une unité constante ; 7/7 plans ne
  valent pas « 95 % » d'une phase qui attend sa recette).
- État d'exigence intermédiaire « livré, non vérifié » (`- [~]`) : second vocabulaire hors GSD, ignoré de
  `check-requirements-survival` et du moteur — la couche de synonymes à éviter.
- Liste d'étapes déclarée en frontmatter (`etapes:`) et cochée à la main : vert déclaré, non lu.
- B pourra revenir pièce par pièce si un besoin réel apparaît après la Phase 68.

### Arbitrages ultérieurs de Samuel (AskUserQuestion session principale, 2026-11-03)

- **P69-D-10 (ordre 69 avant 68).** Réponse de Samuel, mot pour mot : « 69 avant 68 (Recommandé) ». La
  Phase 68 dépend de la 69 : « Depends on » de la 68 mis à jour dans le ROADMAP ; la 68 consomme `avancement`.
- **P69-D-11 (refonte mobile hors 69).** Réponse de Samuel : « Phase à part (Recommandé) ». La refonte mobile,
  I1 et O5 relèvent de la Phase 70 « Finitions UI du cockpit » (inscrite 2026-11-03) ; les déclencheurs des
  deux entrées BACKLOG du cockpit y renvoient. La 69 n'a aucune exigence sur ce sujet.

### Point ouvert

- **Ligne `phase` du DAG de la 67** : à poser côté mission 67 (Samuel la traite, même date).

</decisions>

<canonical_refs>
## Canonical References

- `.planning/notes/2026-11-03-cockpit-progression-en-cours.md` — constat, causes C1-C5, options A et B.
- `plugin/cockpit/scripts/vf-cockpit-project.mjs` (`phaseStatus`, `sums`, pied de jalon, rattachement des
  missions) et `plugin/cockpit/scripts/vf-cockpit-planning.mjs` (`readPlanning`).
- `.planning/workstreams/fiabilite/phases/VFDO-67-cockpit-floorplan-socle-partage/67-CONTEXT.md` — P67-D-02
  (aucun appel sortant), P67-D-12 (socle JSON versionné).
- Phase 68 (ROADMAP) — consommatrice de `readPlanning`.

</canonical_refs>
