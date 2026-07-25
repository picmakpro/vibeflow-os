# Audit complet VibeFlow — 2026-07-25

Synthèse croisée de 5 audits parallèles menés sur v2.31.0 (branche `chore/version-sync-et-report-etape-12`) :

1. **vibeflow-validator** (conformité 5 phases) — rapport détaillé : `reports/validator/2026-07-25-validator.md` — **Status WARN, score 58/100**
2. **Dev quotidien** — fluidité des longues tâches de coding, friction, concurrence des verbes
3. **Monteur de lab** — onboarding, généricité multi-métier, gouvernance
4. **Redondances & concurrence** — recouvrements VibeFlow ↔ GSD ↔ Superpowers ↔ natif
5. **Orchestration & parallélisation** — topologie des équipes, goulots séquentiels, coût de contexte

---

## Verdict global

**Le capital du framework est réel et rare** : la philosophie « gates machine plutôt que prose » (cloisonnement par `tools:`, rapports typés ADR-053, halt conditions, garde-fous autonomes, frontières d'altitude ADR-055) est d'un niveau que peu de frameworks atteignent. **Mais trois maladies structurelles le grèvent** :

1. **Verticalité** — trop d'étages d'agents opus qui wrappent des appels uniques ; une mission type paie ~100-200k tokens de pure relecture par étape.
2. **Duplication de surface** — la couche de synonymes vf-* double un catalogue gsd-*/superpowers qui reste exposé en session ; la concurrence de routage que la couche prétend résoudre est celle qu'elle crée.
3. **Enforcement non branché** — le repo distribue la meilleure doctrine d'enforcement de l'écosystème et ne se l'applique pas : zéro CI, gates qui sortent vert sans rien vérifier, doc utilisateur fausse sur 13 versions sur 16.

Et un constat transversal : **la machine est un pipeline séquentiel sûr, pas un orchestrateur parallèle** — alors que le DAG et les juges read-only rendent la parallélisation déjà sûre par construction. Il ne manque que les consignes de dispatch concurrent.

---

## A. Ce qui est excellent — à préserver absolument

Convergence des 5 audits :

- **Rapports typés ADR-053** `{statut, findings[action], noeuds_debloques}` + lock TTL/heartbeat + DAG avec `reopen` : fin de l'interprétation de prose (`dev-orchestrator/references/mission-flow.md:91-117`).
- **Cloisonnement anti-triche par les tools, pas par la prose** (Pattern 12) : juges sans Write/Edit, workers sans Task, allowlist `Agent(vf-test-runner, vf-app-fixer)`, triple couche `vf-internal`, linté par `check-agents.sh` (ADR-044).
- **Les 6 garde-fous autonomes** (`autonomous-guardrails.md:24-82`) : anti-thrash 3 essais, anti-régression avec revert, arrêt vert-ou-plafond, séparation code/tests, commit atomique, recherche doc bornée. Exactement ce qu'il faut pour une nuit d'exécution.
- **Halt conditions déterministes** : 5 codes + seuils numériques + escalade structurée avec options (`patterns/11-halt-conditions.md:29-60`).
- **L'engine d'install scopé** (`_internal/vibeflow-update.sh`, 834 L) : scope user/project/local, backup, baseline mandatory data-driven sans nom en dur, convergence des modules retirés, ~20 suites de tests. `resolve-deps.sh` (BFS anti-cycle, 60 L) exemplaire.
- **La frontière d'altitude ADR-055** (planning lab vs moteur GSD, `detect-gsd-engine.sh`) : frontière détectée par script, pas par prose. **C'est le modèle à généraliser pour absorber les recouvrements restants.**
- **Densité ADR-029 irréprochable** : pire agent 124/250 L, pire skill 485/500. Synchro bilingue parfaite, triade VERSION/module.json/CHANGELOG alignée 17/17, tag de release ✓.
- **Anti-hallucination systémique** : bundles WIP marqués `proposable:false` plutôt que vendus, kpi-analyst « aucun chiffre inventé », index factuel auto-généré (D4) + test d'exhaustivité T14.
- **Découpes saines à NE PAS fusionner** : `vf-gaps` vs `/vf-audit` (produit vs lab), `software-architecture` vs `audit-architecture`, `mobile-test` vs `mobile-test-team` (la séparation runner/fixer EST le garde-fou), chargement on-demand des références.

---

## B. Maladie 1 — Verticalité : trop d'étages, tout en opus

### Constat (audits 2 + 5 convergents)

- **Chemin équipe = 5-6 contextes d'agents** entre l'utilisateur et le code : `vibeflow-dev` → `vf-dev-manager` → `vf-coder` → skills GSD → sous-agents gsd-* → (`vf-reviewer` → `gsd-code-reviewer`).
- **`vf-reviewer` (37 L) et `vf-auditer` (43 L) sont des wrappers d'un seul appel Task** — un contexte opus complet pour relayer + dédupliquer (`agents/vf-reviewer.md:21-22`, `agents/vf-auditer.md:28-29`). `vf-coder` a lui une vraie valeur (tenir la boucle fix→re-revue).
- **Les 7 agents de l'équipe sont `model: opus`** — en contradiction avec la doctrine du même module : « Executor/Checker : sonnet » (`references/GSD-PIPELINE.md:82-90`).
- **~100-200k tokens de pure relecture par étape** : brief minimal + « le disque est la source de vérité » = 7-9 contextes à froid qui relisent chacun ROADMAP/STATE/PROJECT/CONCERNS. Sur 4 étapes : ~0,5M tokens de surcoût structurel, tout en opus. Aucun digest de handoff n'amortit.
- **Le même diff peut être jugé 3 fois** : plan-checker, boucle revue de vf-coder, recoupement `*-VERIFICATION.md` du manager.
- **Bug : checkpoint interactif mort.** `vf-coder` invoque `gsd-discuss-phase` (interactif) mais n'a pas AskUserQuestion dans ses tools (`agents/vf-coder.md:4`, `:24`) et rien ne lui impose `--auto` → cadrage auto-répondu silencieusement ou blocage en mission.

### Remèdes

1. **Démotion de modèle par rôle** (préalable à toute parallélisation) : workers (coder/app-fixer/test-runner) et juges → sonnet ; opus réservé au manager et au router. Aligne le code sur la doctrine déjà écrite.
2. **Aplatir d'un étage** : le manager/coder dispatche directement `gsd-code-reviewer` / `gsd-security-auditor` avec le contrat typé injecté dans le mandat — supprime vf-reviewer/vf-auditer sans perdre le cloisonnement (ces agents gsd n'ont pas Edit non plus).
3. **Imposer le mode non-interactif** dans `vf-coder.md` (`gsd-discuss-phase --auto` / mode assumptions).
4. **Digest de mission** (30 lignes : étape, décisions, contraintes, fichiers) produit par le manager, injecté dans chaque mandat — le disque reste la vérité, le digest est un cache.
5. **Supprimer la double revue** : si le rapport typé de vf-coder dit `passed` + verdict PASS, le manager ne re-dispatche pas de revue sur la même étape.
6. **Supprimer la prose des rapports workers** (garder bloc typé + détail sur disque) — le manager a déjà consigne de ne pas la lire.

---

## C. Maladie 2 — Duplication de surface et concurrence de routage

### Constat (audit 4, corroboré par 2)

- **30 des 36 verbes vf-* sont des renommages purs** (« Invoque le skill gsd-X » + boilerplate reframe répété ×30) : ~935 L de traduction, pas de logique.
- **La table de routage existe en 4 exemplaires** à synchroniser : matrice des ✘ dans les descriptions (122 renvois négatifs), digest `vf-dev/SKILL.md`, tables `AGENT.md:47-125`, `intent-routing.md` — avec un test machine payé juste pour tenir la quadruplication cohérente.
- **Double catalogue permanent** : ~45 entrées vf-* PAR-DESSUS ~60 gsd-* + superpowers, tous visibles et déclencheurs en session. La rule `vf-verb-precedence` n'est que de la prose ; en mode dégradé (< v2.1.198) rien n'arbitre. Trois frameworks revendiquent le premier geste (vf-verb-precedence vs superpowers:using-superpowers vs descriptions gsd-*).
- **Doctrines contradictoires** : `vf-decide` interdit de router vers un agent en direct (`SKILL.md:22`) mais `vf-dev-manager.md:59` dispatche `gsd-advisor-researcher` en direct. `commands/vf-planning.md:2` répond encore à « où en est-on ? » contre ADR-055.
- **3 objets nommés `skill-creator`** (agent module, skill module, skill Anthropic) dont deux copies verbatim de 485 L dans le repo (diff vide).
- **Quatuor amont** (explore/brainstorm/spike/spec) + vf-decide : 5 verbes dont la frontière « idée floue vs formulée » est maintenue à la main dans 5 endroits.
- **Poids mort** : `docs/reference/` doublon divergent de `plugin/reference/content/` (832K, drift déjà entamé sur 2 fichiers) ; `.superpowers/sdd/` 232K + `docs/superpowers/` 172K d'artefacts de session commités ; `gsd-skills-index.md` snapshot machine-spécifique (chemin `/Users/samuel/...`) versionné et distribué.

### Remèdes

1. **Neutraliser la concurrence lexicale à la racine** : à l'install des verbes, dé-publier/préfixer les descriptions des skills gsd-* doublonnés (via `gsd-surface`, déjà routé) — un seul candidat au niveau 1 du routage au lieu d'une préséance par prose.
2. **Une seule source de routage** : `intent-routing.md` comme unique table, les 3 autres copies générées ou réduites à un pointeur. Le boilerplate reframe ×30 → une rule unique.
3. **Fusionner `/vf-dev` dans l'agent** (ou le réduire à 3 lignes) ; fusionner le quatuor amont en 2 verbes (vf-explore absorbe brainstorm ; vf-spike reste).
4. **Purger** : `docs/reference/` (garder `plugin/reference/` seul canon), artefacts `.superpowers/sdd/` et `docs/superpowers/`, copie verbatim du skill-creator, `gsd-skills-index.md` régénéré à l'install plutôt que versionné.
5. **Trancher l'autorité skill-creator** par une frontière machine (comme ADR-055), pas par « sole authorized channel » en prose.

---

## D. Maladie 3 — L'enforcement non branché (validator, score 58/100)

- **F13 critique — les gates rendent un vert non mérité** : 7 gates sortent `exit 0` quand la cible est absente (« cible absente = cible conforme ») : `check-agents.sh` (même `--strict`), `check-debug-research.sh`, `audit-infra.sh`, `check-version-sync.sh`… Le flag `--agents-dir=` existe et fonctionne ; rien ne l'utilise. `CLAUDE.md:46` « machine-enforced » est faux sur ce repo : aucun agent livré n'est vérifié.
- **F3 release-bloquant — le validator déclare 3 skills inexistants** (`dette-detector`, `checkpoint`, `agent-density-auditor` — template only) : trouvé indépendamment par 3 des 5 audits, et constaté en conditions réelles (phases 2-3 menées à la main). `/checkpoint`, documenté dans 8+ fichiers, n'existe pas.
- **F1/F2 — le README ment sur 13 versions sur 16** : conductor affiché 1.8.2 pour v1.12.2 réel, dev-orchestrator 1.3.0 pour v1.8.1, « 14 verbes » pour 31 livrés, kpi-analyst absent. `check-version-sync.sh` écrit contre ce sinistre exact ne lit jamais `plugin/*/VERSION`.
- **F6 — ADR-029/ADR-031 : 325 citations, zéro définition** (`docs/ADR.md` ne couvre que ADR-046+). **ADR-031 porte deux doctrines incompatibles** : « validation humaine obligatoire » (CLAUDE.md, conductor, validator) vs « vigilance support runtime » (`VIBEFLOW_CORE.md:239`, infrastructure-audit). Toute citation est ambiguë — et non réconciliée avec le pipeline autonome (`gsd-audit-fix` « fix, test, commit »).
- **F16 — clauses de refus orphelines** : `human-validator`, `quality-gate-client` invoqués comme gates bloquants par des agents terminaux… n'existent nulle part.
- **1 test rouge sur `main`, zéro CI, `core.hooksPath` non câblé, `reports/validator/` vide avant aujourd'hui.**

### Remède à plus fort levier

**Un unique workflow CI** qui ne demande aucun gate nouveau — brancher ceux qui existent : 31 suites (avec assertion de découverte non vide), 2 gates de release, `check-agents.sh --strict --agents-dir=` par module. Corrige F13/F14/VG-1 d'un coup et rend vraie la promesse « machine-enforced ».

---

## E. Parallélisation — le plan d'activation (audit 5)

Le parallélisme existe déjà aux extrémités (waves gsd-execute, mappers, panels ×3) mais **l'étage équipe est 100 % séquentiel** — zéro occurrence de « parallèle » dans `vf-dev-manager.md`, `mission-flow.md` et les 12 patterns, alors que le protocole générique le prévoit (`delegation-protocol.md:25-28`).

Ordre d'activation (les garde-fous existent déjà) :

1. **Revue ∥ audit après build** — deux juges read-only (Pattern 12), zéro risque de collision. Le manager fusionne les findings, UN seul `dag.sh reopen`.
2. **Exploiter la frontière DAG** — `dag.sh ready` renvoie une liste : consigne explicite « ≥2 nœuds ready à périmètres de fichiers disjoints → Task multiples dans un message ». Garde-fous : périmètre déclaré à l'`add`, HALT-5 en filet, `isolation: worktree` pour les cas douteux (déjà validé par check-agents.sh, jamais utilisé).
3. **Recherche doc ADR-045 en background** au lieu du gate synchrone 3-sauts ; et donner context7/WebSearch à `vf-test-orchestrator` (le cloisonnement anti-triche concerne code/tests, pas la doc) : 3 sauts → 1.
4. **Pipelining N/N+1** — cadrage+plan de l'étape suivante pendant l'exécution de la courante ; plan « provisoire » re-validé par le plan-checker existant. Modéliser discuss/plan/execute comme nœuds DAG par étape.
5. **Boucle mobile** — fixes parallèles sur fichiers disjoints (le re-run complet + anti-régression protègent) ; seule l'exécution Maestro reste sérielle (un simulateur).

**Préalable non négociable : la démotion de modèle (B.1)** — sinon la parallélisation multiplie un coût déjà excessif.

---

## F. Multi-métier — promesse vs offre (audit 3)

- **Doctrine sincèrement générique** (VIBEFLOW_CORE « universel », P7 Transposition, planning-core anti-biais-dev avec extensions editorial/pipeline/dossiers) mais **offre livrée ~70/30 dev** : dev-orchestrator 40+ fichiers vs bundles content/growth/business **doc-only** (`proposable: false`, zéro skill/script/test — des plans de fabrication pour le fan-out skill-creator, pas des modules). kpi-analyst est l'exception finie.
- **Le messaging contredit la promesse** : plugin.json « Orchestrateur de développement », catégorie `development`, README « development orchestrator ». Un acheteur non-dev ne se reconnaît nulle part.
- **La généralisation est aux deux tiers faite mais en deux lignées qui ne se parlent pas** : lignée générique (`orchestrator-template` + `metier-orchestration` + `delegation-protocol` + templates lead/explorer/reviewer/tester) vs lignée dev (lock+DAG+rapports typés, uniquement dans dev-orchestrator).
- **Sur-gouvernance pour un lab solo** : validator Phase 4 = audit des architectures d'audit (3 étages de méta), registre EVALS obligatoire dès l'init, cadences mensuelle/trimestrielle intenables en solo → la dette procédurale devient elle-même un finding (boucle de culpabilisation). Stop-hook planning `block` par défaut sur tous profils. Lock+DAG « non négociables » même pour 3 étapes solo — alors que la Phase 9 disait « non implémenté tant que les collisions ne sont pas observées ».
- **Onboarding profond** : baseline minimale = 6 modules + ~9 hooks avant la première action métier ; time-to-first-value en heures pour « un lab marketing ce soir ».

### Remèdes

1. **Extraire un « team-kernel » transverse** (dag.sh, driver-lock.sh, contrat Pattern C, 5 HALT) consommable par tout orchestrateur métier ; paramétrer par métier : spécialistes, gates, vocabulary-map, définition de « vert » (tests → recette → EVALS). Instancier design en premier (l'asymétrie est flagrante : zéro équipe design).
2. **Proportionner la gouvernance au profil** : profil léger = Stop-hook `warn`, validator Phases 1-3 (Phase 4 opt-in), EVALS optionnel, lock+DAG réservés aux missions ≥ SEUIL_EQUIPE ou multi-session.
3. **Mode « lab express »** ≤15 min : 3 questions, scope auto-détecté (cwd git → project), gates en warn, capacités fabriquées en tâche de fond, dette affichée.
4. **Réconcilier promesse et offre** : finir UN bundle de bout en bout (content, le plus avancé) et le passer `proposable:true` — ou assumer « dev+design maintenant » dans le messaging.

---

## G. Bugs et incohérences ponctuels (checklist corrective)

| # | Constat | Fichier | Trouvé par |
|---|---|---|---|
| 1 | Validator déclare 3 skills inexistants → échoue à son propre Gate C | `plugin/validator/AGENT.md:6-13` | 3 audits |
| 2 | ADR-031 = deux doctrines incompatibles ; ADR-029/031 cités 325×, jamais définis | `VIBEFLOW_CORE.md:239` vs `CLAUDE.md`/`docs/ADR.md` | 2 audits |
| 3 | 7 gates `exit 0` sur cible absente ; `--agents-dir=` jamais utilisé | `conductor/scripts/check-agents.sh` et al. | validator |
| 4 | README : 13/16 versions fausses, « 14 verbes » pour 31 | `README.md` / `README.fr.md` | validator |
| 5 | vf-coder sans AskUserQuestion invoque un skill interactif | `agents/vf-coder.md:4,24` | dev |
| 6 | Globs mobile matchent tout Next.js App Router | `mobile-test-team/rules/mobile-verify-gate.md:2-8` | dev |
| 7 | `docs/reference/` doublon divergent de `plugin/reference/content/` | `docs/reference/` | redondances |
| 8 | Artefacts de session commités (232K + 172K) | `.superpowers/sdd/`, `docs/superpowers/` | redondances |
| 9 | skill-creator dupliqué verbatim (485 L ×2) | `plugin/skill-creator/...` vs `reference/.../templates/` | 2 audits |
| 10 | `gsd-skills-index.md` snapshot machine-spécifique versionné | `references/gsd-skills-index.md` | redondances |
| 11 | `vf-decide` interdit ce que fait `vf-dev-manager` (panel direct) | `vf-decide/SKILL.md:22` vs `vf-dev-manager.md:59` | redondances |
| 12 | `vf-planning.md` répond encore à « où en est-on ? » contre ADR-055 | `plugin/commands/vf-planning.md:2` | redondances |
| 13 | Clauses de refus orphelines (`human-validator`, `quality-gate-client`) | agents terminaux | validator |
| 14 | `/checkpoint` documenté 8+ fois, n'existe pas | divers | validator |
| 15 | module.json re-duplique VERSION ; 6 sources de version racine | `plugin/*/module.json` | lab |
| 16 | kpi-analyst référence un « Hub » inexistant | `kpi-analyst/SKILL.md:8` | lab |
| 17 | 1 test rouge sur `main`, zéro CI, `core.hooksPath` non câblé | — | validator |

---

## H. Plan d'action priorisé

### Vague 1 — Quick wins (jours ; aucun changement d'architecture)

1. CI unique branchant les gates existants (D) — le geste à plus fort levier du repo.
2. Démotion de modèle des workers/juges → sonnet (B.1).
3. Corriger le frontmatter validator + `/checkpoint` fantôme + clauses orphelines (G.1, 13, 14).
4. `gsd-discuss-phase --auto` imposé à vf-coder (G.5).
5. Revue ∥ audit + consigne de dispatch parallèle sur la frontière DAG (E.1-2).
6. Fixer les globs mobile (G.6). Purger docs/reference, artefacts de session, doublon skill-creator (G.7-9).
7. `bump.sh` générateur de versions + régénérer le README depuis `plugin/*/VERSION` (G.4, 15).
8. Définir ADR-001→045 dans `docs/ADR.md` (au minimum 029 et 031, en scindant 031 en deux identifiants).

### Vague 2 — Allègements (semaines)

9. Aplatir vf-reviewer/vf-auditer ; supprimer double revue et prose des rapports (B.2, 5, 6).
10. Digest de mission (B.4). Recherche doc en background + web pour vf-test-orchestrator (E.3).
11. Lock+DAG conditionnés à la taille de mission ; gouvernance proportionnée au profil (F.2).
12. Dé-publication des descriptions gsd-* doublonnées à l'install ; source de routage unique (C.1-2).
13. Fusion /vf-dev + quatuor amont → 2 verbes (C.3).

### Vague 3 — Refontes structurantes (à cadrer comme phases de roadmap)

14. Team-kernel transverse + première équipe non-dev (design) (F.1).
15. Pipelining N/N+1 dans le DAG (E.4).
16. Mode « lab express » + finir le bundle content de bout en bout (F.3-4).
17. Généraliser la méthode ADR-055 (frontière machine) aux recouvrements restants : skill-creator ×3, vf-debug/systematic-debugging, entrées de revue ×6.
