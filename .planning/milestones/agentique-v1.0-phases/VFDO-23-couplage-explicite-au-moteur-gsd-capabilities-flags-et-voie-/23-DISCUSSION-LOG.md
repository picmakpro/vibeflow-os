# Phase 23: Couplage explicite au moteur GSD — Discussion Log

> **Trace d'audit uniquement.** Ne pas utiliser comme entrée d'un agent de planification, de
> recherche ou d'exécution. Les décisions sont dans `23-CONTEXT.md` — ce journal conserve les
> alternatives qui ont été écartées, et pourquoi.

**Date :** 2026-08-01
**Phase :** 23 — Couplage explicite au moteur GSD : capabilities, flags et voie unique
**Zones discutées :** les 7 lacunes du ROADMAP, toutes sélectionnées par Samuel, traitées dans
l'ordre imposé (sûreté d'abord)
**Format :** questions groupées par zone (4 par appel), à la demande de Samuel — le mode `--batch`
amont a été écarté pour son rendu texte, le regroupement conservé avec le rendu cochable.

---

## Zone 1 — Contrat de checkpoint et continuation (Lacune 6, sûreté)

### Q1 — Comment le `gate` GSD remonte dans le statut maison du manager

| Option | Description | Retenue |
|--------|-------------|---------|
| Champ `gate` au rapport | Mapping écrit + champ obligatoire dans le bloc typé, patron `estimate`/`actuals` | ✓ |
| Statut dédié `checkpoint_bloquant` | Plus expressif, mais propagation dans toute la chaîne typée | |
| Doctrine seule | Aucun changement de contrat — mais rien ne prouve qu'un checkpoint a eu lieu | |

**Notes :** les préconditions non satisfaites (`gsd-executor.md:150`) ont été rattachées à la même
règle dans l'option retenue — un refus d'auto-approbation amont est un refus, quel qu'en soit le
motif.

### Q2 — Régime du flag `_auto_chain_active`

| Option | Description | Retenue |
|--------|-------------|---------|
| Reset + garde machine | Le manager désarme le flag en début de mission + la suite échoue sur `--auto` dans un fichier du module | ✓ |
| Reset seul | Rien n'empêche un futur agent de réécrire `--auto` | |
| Doctrine seule | Laisse intact un flag posé par une session antérieure — l'état le plus dangereux | |
| Interdire `--auto` partout | Casserait `discuss` en mandat worker (pas d'`AskUserQuestion`) | |

**Notes :** fait établi pendant le cadrage et absent du ROADMAP — `--auto` sur `gsd-discuss-phase`
(prescrit par `vf-coder.md:27`) persiste le flag **en config**, pas en mémoire de session.

### Q3 — Profondeur de la continuation

| Option | Description | Retenue |
|--------|-------------|---------|
| 4 blocs dans le mandat | Contrat complet porté par le bloc typé, `dag.sh` inchangé | ✓ *(puis révisée)* |
| Minimal — escalade sans reprise | Travail refait, ou commits orphelins | |
| 4 blocs + `dag.sh` étendu | Transverse au module `conductor`, tous métiers | |

**Notes :** **révisée en fin de cadrage** (voir « Vérification en cours de route » ci-dessous) —
les 4 blocs sont un contrat interne au moteur. Décision finale : minimum de reprise (D-03).

### Q4 — Halt en mission autonome sur `gate="blocking-human"`

| Option | Description | Retenue |
|--------|-------------|---------|
| Halt du nœud, mission continue | Branches indépendantes du DAG poursuivies, constat consigné | ✓ |
| Halt dur de toute la mission | Gaspille une nuit sur des branches sans rapport | |
| Selon la centralité du nœud | Plus fin, mais introduit un jugement | |

---

## Zone 2 — Doctrine de flags de cycle (Lacune 3)

### Q1 — Réglage de la recherche

| Option | Description | Retenue |
|--------|-------------|---------|
| Gradation sur critère factuel | `--research` sur lib/framework/version/domaine non cartographié, `--skip-research` sinon | ✓ |
| Toujours `--research` | Volume payé pour rien sur les étapes de continuité | |
| Toujours `--skip-research` | Les panels du manager ne couvrent pas le même objet | |

### Q2 — Hébergement de la doctrine

| Option | Description | Retenue |
|--------|-------------|---------|
| Dans `GSD-PIPELINE.md` | Le fichier qui décrit déjà le cycle ; évite un 10ᵉ fichier | ✓ |
| Nouveau `gsd-flags.md` | Symétrie avec `docs-flow.md`, mais frontière à expliquer | |
| Dans `mission-contracts.md` | Déjà le plus gros (16.1 K), et il parle mission, pas cycle | |

### Q3 — Forme de la table capabilities/hooks

| Option | Description | Retenue |
|--------|-------------|---------|
| Générée depuis `render-hooks` | Patron `build-gsd-index.sh`, ne périme pas | ✓ |
| Écrite + gate de comparaison | Plus lisible, mais réécriture manuelle à chaque montée | |
| Écrite sans garde | Devient fausse en silence — le défaut déjà constaté (1.8.0 vs 1.9.0) | |

### Q4 — Forme de la doctrine

| Option | Description | Retenue |
|--------|-------------|---------|
| Allowlist stricte | Un flag nouveau arrive fermé, s'ouvre par décision | ✓ |
| Doctrine exhaustive par sous-phase | Volumineuse et périmée dès que l'amont bouge | |
| Liste d'interdits seuls | Un flag inconnu arrive ouvert — reproduit la Lacune 5 | |

---

## Zone 3 — Voie unique vs agent nu (Lacune 2)

### Q1 — Régime du dispatch direct

| Option | Description | Retenue |
|--------|-------------|---------|
| Interdit sec — le skill est la voie | Les mentions disparaissent de `vf-coder.md` | ✓ |
| Autorisé sous déclaration | Laisse le worker arbitrer ce qu'il ne peut pas évaluer | |
| Allowlist de situations | Seconde liste à maintenir, débat rouvert à chaque ajout | |

### Q2 — Voie de la continuation

| Option | Description | Retenue |
|--------|-------------|---------|
| Nouveau `vf-coder`, voie skill | Aucune exception à la voie unique | ✓ |
| Exception nommée `gsd-executor` | Honnête vis-à-vis du moteur, mais rouvre la porte | |
| Escalade humaine systématique | Contredirait la décision de zone 1 | |

**Notes :** l'hypothèse sous-jacente (« le skill sait reprendre un plan partiellement exécuté ») a
été **vérifiée en fin de cadrage** à la demande de Samuel — confirmée, voir ci-dessous.

### Q3 — Garantie machine

| Option | Description | Retenue |
|--------|-------------|---------|
| Test sur les fichiers du module | Même extension de suite que le gate `--auto` | ✓ |
| Champ `voie` au rapport | Dépendrait de la vigilance de lecture, pas d'un gate | |
| Les deux | Un champ de plus dans un contrat qui en gagne déjà plusieurs | |

### Q4 — Allowlists `Agent(...)`

| Option | Description | Retenue |
|--------|-------------|---------|
| Purger les agents interdits | `gsd-planner` et `gsd-executor` sortent de `tools:` | ✓ |
| Garder, doctrine seule | Un contrat documenté autoriserait ce que la doctrine interdit | |
| Purger + auditer les 20+ entrées | Périmètre à part ; risque sur l'étage design → **différé** | |

---

## Zone 4 — Étages de revue et d'audit (Lacune 1)

### Q1 — Revue de diff : hook GSD vs `revue-N`

| Option | Description | Retenue |
|--------|-------------|---------|
| Disjoints, critère écrit | Hook = diff d'un plan ; `revue-N` = diff de jointure. Patron ADR-061 | ✓ |
| Éteindre le hook | Un `gsd-execute-phase` lancé hors mission perdrait sa revue | |
| `revue-N` en jointure seule | Économie réelle mais revirement d'ADR-060 | |

### Q2 — Audit sécurité : hook `secure-phase` vs `vf-auditer`

| Option | Description | Retenue |
|--------|-------------|---------|
| Disjoints — `vf-auditer` recoupe `CONCERNS.md` | Delta que le hook ne peut pas produire | ✓ |
| Supprimer `vf-auditer` du cycle | L'agent perdrait sa raison d'être en mission | |
| Conditionné au verdict du hook | On perdrait le recoupement là où il sert le plus | |

### Q3 — Verdicts des hooks au rapport

| Option | Description | Retenue |
|--------|-------------|---------|
| Verdicts au bloc typé | Le coût réel devient lisible au lieu d'être payé deux fois en aveugle | ✓ |
| Non — contrat déjà chargé | La doctrine seule suffirait | |
| Oui, mais lu depuis le disque | Le manager consommerait du contexte à chaque étape | |

### Q4 — Traçage de l'arbitrage

| Option | Description | Retenue |
|--------|-------------|---------|
| Extension d'ADR-061 | Une seule voix sur une seule question (ADR-057) | ✓ |
| Nouvel ADR dédié | ADR-061 deviendrait partiellement obsolète sans le dire | |
| Doctrine seule, pas d'ADR | Un arbitrage tranché contre ADR-060 sans trace ADR | |

---

## Zone 5 — Alignement du `config.json` (Lacune 5)

### Q1 — Périmètre

| Option | Description | Retenue |
|--------|-------------|---------|
| Gate machine générique | Vaut pour tous les labs ; lit les clés connues depuis `gsd-core` | ✓ |
| Réparer ce lab seulement | L'avertissement resterait chez tous les autres utilisateurs | |
| Gabarit posé par l'engine | Ne couvrirait pas les labs déjà déployés | |

### Q2 — Blocs `gates` et `safety`

| Option | Description | Retenue |
|--------|-------------|---------|
| Supprimer + reporter l'intention | Vers `human_verify_mode` et ADR-031 — rien n'est perdu | ✓ |
| Supprimer sec | Effacerait l'intention de `confirm_plan` sans la réimplanter | |
| Garder, documentés inertes | JSON n'a pas de commentaires ; l'avertissement persisterait | |

**Notes :** vérifié dans `bin/lib/config.cjs` — les 8 clés `gates.*` et les 2 `safety.*` n'ont
**aucun** équivalent amont. Elles n'ont pas de destination, elles ne sont pas mal nommées.

### Q3 — Toggles à inscrire

| Option | Description | Retenue |
|--------|-------------|---------|
| Ceux du cycle, valeur décidée | `code_review`, `pattern_mapper`, `node_repair(_budget)`, `ui_review` | ✓ |
| Les 44 capabilities | Fichier énorme à maintenir, majorité hors sujet pour ce lab | |
| Aucun — le gate suffit | Un signal advisory ignoré redérive vers le pilotage par omission | |

### Q4 — Sévérité du gate

| Option | Description | Retenue |
|--------|-------------|---------|
| Advisory, exit 0/3 | Patron `check-doc-drift.sh` ; constate le fait, laisse le jugement | ✓ |
| Bloquant en CI | CI rouge dès qu'une clé est renommée en amont — panne subie | |
| Mixte selon le type de défaut | Deux régimes dans un script, deux contrats d'exit | |

---

## Zone 6 — Briques dormantes et tension `ship` (Lacune 4)

### Q1 — Tension `gsd-ship`

| Option | Description | Retenue |
|--------|-------------|---------|
| PR à la main confirmée, PIPELINE corrigé | ADR-059/064 priment ; la doctrine dit enfin la pratique | ✓ |
| Le manager passe à `gsd-ship` | Contredirait ADR-059 et ADR-064 sans vérification préalable | |
| Hybride `gsd-pr-branch` | Frontière fine, coûteuse à spécifier, dépendance de plus | |

### Q2 — Absence d'outil de debug chez le manager

| Option | Description | Retenue |
|--------|-------------|---------|
| Le manager délègue, `vf-coder` invoque `gsd-debug` | Voie unique appliquée ; le manager gagne le moment, pas l'outil | ✓ |
| `gsd-debugger` en allowlist du manager | Rouvrirait le dispatch d'agent nu | |
| `gsd-forensics` d'abord | Étage systématique pour des blocages souvent triviaux | |

### Q3 — Briques dormantes retenues (sélection multiple)

| Brique | Retenue |
|--------|---------|
| `gsd-extract-learnings` | ✓ |
| `gsd-add-tests` | ✓ |
| `gsd-spec-phase` | ✓ |
| `gsd-undo` / `gsd-forensics` | ✓ |

**Notes :** Samuel a retenu **les quatre**. Aucune brique proposée n'a été écartée.

### Q4 — Forme des moments déclencheurs

| Option | Description | Retenue |
|--------|-------------|---------|
| Table de moments déclencheurs | Gabarit D-08 de la Phase 22, faits constatables (ADR-055 §3) | ✓ |
| Nœuds DAG conditionnels | Alourdirait le plan de bataille de nœuds rarement posés | |
| `intent-routing.md` seul | Couvrirait la conversation, pas la mission | |

---

## Zone 7 — Budgets de boucle additionnés (Lacune 7)

### Q1 — Traitement du cumul

| Option | Description | Retenue |
|--------|-------------|---------|
| Consigner, budgets inchangés | Objets disjoints ; on décidera sur chiffres, pas avant | ✓ |
| Consigner + réduire à 2 tours | Réduirait un budget dont le rendement fut mesuré à 3 | |
| `node_repair: false` | Éteindrait une réparation au grain tâche | |
| Budget global en tentatives | Suppose une observabilité non acquise | |

### Q2 — Traçabilité de `node_repair`

| Option | Description | Retenue |
|--------|-------------|---------|
| À vérifier au RESEARCH, champ si observable | Un manque nommé vaut mieux qu'un chiffre inventé | ✓ |
| Ne tracer que les tours d'équipe | Le rapport resterait une estimation | |
| Exiger l'observabilité | Ferait dépendre la phase d'un comportement hors contrôle | |

### Q3 — Partage du budget

| Option | Description | Retenue |
|--------|-------------|---------|
| Un budget par étape, partagé | Ferme le contournement revue → comblement rebaptisé | ✓ |
| Un budget par boucle | Laisserait la voie de contournement ouverte | |
| Partagé par mission | Pénaliserait les étapes tardives d'une longue mission | |

### Q4 — Rapport sur budget épuisé

| Option | Description | Retenue |
|--------|-------------|---------|
| `blocked` + décompte complet | Un chiffre réel plutôt qu'un « 3 tours » masquant jusqu'à 9 | ✓ |
| `human_needed` | Mélangerait deux causes très différentes sous un statut | |
| `blocked` + proposition | Produite par l'agent qui vient d'échouer 9 fois | |

---

## Vérification en cours de route (demandée par Samuel)

Plutôt que de laisser l'hypothèse de continuation au RESEARCH, Samuel a demandé de vérifier
immédiatement si `gsd-execute-phase` sait reprendre un plan partiellement exécuté. Résultat
(`execute-phase.md:178-192`, `:1093-1125`, `:1642` ; `execute-plan.md:326`) :

- **la voie skill sait reprendre**, à deux grains, et porte en prime `safe_resume_gate` — un
  garde-fou anti-commits-orphelins qu'aucun dispatch d'agent nu n'aurait. **Zone 3 confirmée et
  mieux fondée** ;
- **les 4 blocs sont un contrat interne au moteur** — le « *You will NOT be resumed* » s'adresse à
  l'executor, pas à VibeFlow. **La Lacune 6(c) du ROADMAP est mal posée**, et la décision Q3 de la
  zone 1 a été **révisée** en conséquence ;
- **un trou non identifié au ROADMAP est apparu** : `execute-phase` attend une réponse humaine aux
  étapes 4-5 et dans `safe_resume_gate`, or `vf-coder` n'a pas `AskUserQuestion` — alors que
  `vf-dev-manager` l'a.

### Décisions issues de la vérification

| Question | Option retenue | Écartées |
|---|---|---|
| Que porte réellement le bloc typé ? | **Minimum de reprise** (`plan_id`, type, `gate`, « Awaiting ») — zéro duplication du contrat amont (ADR-030) | Les 4 blocs complets ; ne rien porter |
| Qui répond quand le moteur attend un humain ? | **`vf-dev-manager`**, qui porte `AskUserQuestion` ; `gate="blocking-human"` reste hors de sa portée | Le manager tranchant seul ; donner `AskUserQuestion` au worker |

---

## Périmètre

| Option | Description | Retenue |
|--------|-------------|---------|
| Tout dans la Phase 23 | Les 7 lacunes forment un seul objet ; le découpage se fait en plans | ✓ |
| Scinder — sûreté d'abord, reste en 23bis | Livraison plus rapide, mais dépendance de plus | |
| Sortir l'outillage vers la Phase 24 | Recoupement thématique réel, mais la 24 est déjà chargée | |

---

## Claude's Discretion

Aucune zone n'a été laissée à ma discrétion sur le fond — Samuel a sélectionné et tranché les 7
zones. Restent de ma main : le découpage en plans, la structure interne des sections ajoutées, les
noms de scripts, la forme exacte des assertions de test, et la formulation du critère de
disjonction dans ADR-061. Détail en `23-CONTEXT.md` § Claude's Discretion.

## Deferred Ideas

- Audit complet des 20+ entrées d'allowlist `Agent(...)` de `vf-coder` (zone 3, Q4).
- Plafonner le budget global de tentatives une fois des décomptes réels disponibles (zone 7, Q1).
- Inventorier les 44 capabilities dans le `config.json` (zone 5, Q3) — candidat naturel pour la
  Phase 24.
- Adopter `gsd-ship` / `gsd-pr-branch` si l'amont apprend à respecter une branche imposée et un
  verrou d'écrivain externe (zone 6, Q1).
