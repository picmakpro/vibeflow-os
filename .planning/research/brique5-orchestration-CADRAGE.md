# Cadrage — Brique 5 : couche d'orchestration autonome

> Compagnon de `agent-team-integration-PLAN.md`. Date : 2026-07-07.
> Statut : **5b + 5c IMPLÉMENTÉS (2026-07-07)** — module `mobile-test-team` (3 agents cloisonnés
> + rule path-scopée) + câblage `vf-auto`, install/uninstall e2e validés. 5a « cerveau » n'était
> pas nécessaire (déjà couvert par `gsd-autonomous`, voir §1bis). **Preuve finale = un run réel**
> (nesting de sous-agents) encore à faire. Statut module : expérimental.
> *Note 2026-07-26 : archive d'époque — le sommet d'orchestration a été refondu en v2.33.0/v2.34.0
> (bascule agentique + team-kernel). L'action pendante « run réel » n'a jamais été soldée : elle est
> désormais tracée comme condition de sortie du statut expérimental de `mobile-test`(-team).*
> Déclencheur : la question « je dis "fais la phase 3 en auto" et il va jusqu'au bout ? » → **non**,
> il manque le cerveau d'orchestration. Ce document cadre ce qui manque.
> Décisions déjà prises par Samuel : (a) cadrer avant de coder ; (b) **sommet fusionné dans
> `vibeflow-dev`** (pas de second agent `manager`).

---

## 0. Correction de l'évaluation initiale (je me suis trompé)

L'analyse du **code réel** de projet source (pas du spec) invalide deux de mes arguments initiaux :

- ❌ *« 7 agents = budget densité ADR-029 explosé »* → **faux**. Les agents font 25–47 lignes
  (262 au total). Ce sont des orchestrateurs fins, exactement l'esprit ADR-029.
- ❌ *« manager/coder = doublon de vibeflow-dev »* → **imprécis**. `vibeflow-dev` route **une**
  intention (NL → 1 skill). `manager` **pilote une mission** : boucle par phase, dispatche
  plusieurs agents, gère les retours review/audit, marque *done*, enchaîne. Objet différent,
  absent de VibeFlow. C'est le chaînon manquant pour « aller jusqu'au bout ».

Angle manqué : projet source contient **deux** systèmes d'agents sédimentés et contradictoires —
(A) personas + Jira + `overnight_autonomous` (push/PR/auto-merge cloud), (B) les 7 agents GSD
(`.planning/` local, livraison différée). Le `CLAUDE.md` de projet source dit « never use local markdown
files for tracking », ce qui **contredit** les 7 agents. On n'importe **que** l'esprit du système
B ; le système A (couplé Jira/cloud/push) est **hors périmètre**.

Ce qui reste valide de l'éval : un seul sommet ; pas de parité `.agent/` ; contraintes projet source
(no-push, no-mention-IA) = options de projet.

---

## 1. La vraie découverte : VibeFlow a déjà la doctrine

La couche d'orchestration autonome **existe déjà** dans la méthodo VibeFlow, mais seulement en
**documentation** (module `reference`), pas en **capacité exécutable** :

| Doctrine existante | Rôle | Équivalent projet source |
|--------------------|------|------------------|
| **Pattern 09 — `god-execution`** (8 phases) | Orchestration autonome multi-sprints | l'agent `manager` |
| **Pattern 09 — `safe-execute`** (5 phases) | Tâche unitaire rigoureuse | — |
| **Pattern 11 — 5 Halt conditions** | Arrêts durs + escalation | night-run garde-fous |
| **Pattern 10 — Adversarial Plan-Review** | 2 reviewers + Judge | panel de décision |
| **Pattern 12 — Cloisonnement outils** (posé brique 3) | Workers/juges cloisonnés | tools: des 7 agents |

`god-execution` est **plus complet** que le manager projet source (il a la phase Plan-Review adversarial
et la vérif visuelle explicite). Sa **phase 7 « Vérif Visuelle »** (snapshot + comparaison au
critère) **est** le module `mobile-test` qu'on a posé — mais rien ne les relie aujourd'hui.

**Conclusion** : la brique 5 = **matérialiser `god-execution` en exécutable** et le **câbler** sur
les briques déjà posées. On ne copie pas projet source ; projet source est la preuve que le pattern tient.

---

## 1bis. D4 tranché — le « cerveau » multi-phases existe DÉJÀ

Vérification faite : **`gsd-autonomous`** (auquel `vf-auto` délègue déjà) matérialise le squelette
de `god-execution` : découverte des phases via ROADMAP, `discuss → plan → execute` par phase,
mise à jour STATE/ROADMAP, *done*, phase suivante, audit + complete milestone, pauses pour
décisions/blockers. **Le rôle `manager` est donc déjà couvert.**

Ce qui manque **n'est pas** le pilote multi-phases — c'est le **point de vérification** de cette
boucle : `gsd-autonomous` s'arrête aux **gates techniques** (lint / tsc / tests unitaires) via
`gsd-execute-phase`. Il ne **teste pas l'app réelle** (Maestro sur simulateur) et ne **boucle pas
test+fix** sur les échecs de comportement. Pour une app mobile : ça peut compiler et passer les
tests unitaires **mais crasher à l'écran** — et la boucle autonome le déclarerait « done ».

**Recadrage de la brique 5 (réduite et ciblée)** :
- 5a « cerveau » → **déjà là** (`vf-auto`). On ne réimplémente pas le manager.
- 5b « boucle test+fix réelle + workers cloisonnés » → **LE vrai manque**. À construire.
- 5c « câblage » → insérer 5b comme **étape de vérification réelle** dans le flux `gsd-autonomous`
  (phase 7 de `god-execution`), quand le projet est mobile.

C'est aussi la réponse honnête à la question de départ : `vf-auto` va déjà « jusqu'au bout » au
sens *phases enchaînées + gates techniques*. Il n'y va **pas** au sens *l'app tourne vraiment* —
c'est précisément le trou que 5b/5c comblent.

## 2. Objectif de la brique 5

Qu'un utilisateur puisse dire **« fais la phase 3 en autonomie »** et que VibeFlow exécute
`god-execution` de bout en bout : plan → plan-review → exécution → vérif code/tests →
**vérif réelle (mobile via `mobile-test`)** → fix en boucle (garde-fous) → *done* → phase suivante,
avec **arrêt propre** sur halt condition. Sans exposer la plomberie.

---

## 3. Architecture cible (sommet fusionné — décision Samuel)

Pas de nouvel agent `manager`. `vibeflow-dev` **est** le sommet, enrichi d'un **mode
orchestration** = exécuteur de `god-execution`. Il route déjà une intention ; il gagne la
capacité de piloter une mission multi-phases.

```
vibeflow-dev  (sommet unique, mode orchestration = god-execution)
│   délègue phase par phase :
├── cadrage/plan        → gsd-discuss-phase / gsd-plan-phase          (existant)
├── plan-review         → Pattern 10 adversarial                      (doctrine existante)
├── décision zone grise → vf-decide (panel)                           (posé brique 4)
├── exécution           → gsd-execute-phase                           (existant)
├── revue / audit       → vf-review / vibeflow-validator              (existant)
└── boucle test+fix réel → vf-test-orchestrator  ← NOUVEAU (brique 5b)
        ├── vf-test-runner   (écrit/joue les tests, cloisonné .maestro/**, PAS de code app)
        └── vf-app-fixer     (corrige le code, cloisonné src/**, PAS de tests)
             └── pilote le module mobile-test (posé brique 1) pour la vérif réelle
```

Le mode orchestration **applique les halt conditions (Pattern 11)** comme garde-fous et lit un
`night-run.json` optionnel (schéma déjà documenté dans `autonomous-guardrails.md`).

---

## 4. Décomposition

### 5a — Mode orchestration dans `vibeflow-dev` (le cerveau)
- **Référence `references/orchestration-protocol.md`** (déportée on-demand, respecte ADR-029) :
  mappe les 8 phases de `god-execution` aux cibles VibeFlow/GSD concrètes + les 5 halt conditions +
  le critère de passage de phase (*success criteria VRAIS* → *done* → STATE/ROADMAP).
- **Hook léger dans `AGENT.md`** : intention « fais tout / phase X jusqu'au bout / en autonomie
  totale » → charge le protocole et exécute. Reste sous 250 lignes (agent à 144 aujourd'hui).
- Réutilise `vf-decide` (plan-review/zones grises) et la doctrine `autonomous-guardrails.md`.

### 5b — Boucle test+fix matérialisée (les bras)
Trois agents **fins et cloisonnés** (Pattern 12), généralisés depuis projet source :
- **`vf-test-orchestrator`** : tient la boucle (baseline verte, anti-régression revert, anti-thrash
  N=3, arrêt vert/plafond), dispatche les 2 workers, produit le rapport de synthèse. Halt-aware.
- **`vf-test-runner`** : possède les tests, écrit la couverture manquante, **n'affaiblit jamais un
  assert**, joue le pipeline. `tools:` sans `Task`. Cloisonné sur le dossier de tests.
- **`vf-app-fixer`** : corrige **uniquement** le code applicatif, commit atomique. `tools:` sans
  `Task`. Cloisonné hors tests. Ne peut pas modifier un test pour « passer ».

### 5c — Câblage vérif visuelle ↔ `mobile-test`
La phase 7 de `god-execution` (vérif réelle) utilise le module `mobile-test` quand le projet est
mobile (détection de domaine), et les gates techniques (lint/tsc/tests) sinon. C'est le point qui
transforme « le code est écrit » en « l'app marche vraiment ».

---

## 5. Décisions à trancher (avec ma reco)

| # | Question | Options | Reco |
|---|----------|---------|------|
| D1 | `vf-test-orchestrator` = agent ou skill ? | agent (dispatche des workers, contexte isolé) / skill | **Agent** — il faut un contexte isolé qui boucle et dispatche. |
| D2 | Workers `test-runner`/`app-fixer` = agents ? | agents cloisonnés / skills | **Agents** — le cloisonnement anti-triche (Pattern 12) exige des `tools:` restreints, impossible en skill. |
| D3 | Mode orchestration = nouveau `vf-orchestrate` ou montée en gamme de `vf-auto` ? | nouveau verbe / enrichir vf-auto | **Enrichir `vf-auto`** (il délègue déjà à l'autonomie) + référence protocole. Évite un verbe de plus. |
| D4 | Rapport `god-execution` vs `gsd-autonomous` ? | — | **TRANCHÉ** : `gsd-autonomous` = déjà le cerveau multi-phases (via `vf-auto`). Ne pas réimplémenter. Le manque = la vérif réelle + boucle fix (5b/5c). Voir §1bis. |
| D5 | Contraintes projet source (no-push, no-mention-IA) | option projet / ignorer | **Option de projet** + HALT-3 sur push. |

---

## 6. Généralisation (retrait du projet source)

- Chemins `.agent/`, `docs/_mission/`, `.maestro/` en dur → paramètres (le module `mobile-test`
  gère déjà sa config).
- Règles projet source (i18n, THEME, bundle id) → **retirées** des corps d'agents (elles viennent du
  `CLAUDE.md`/RULES du projet cible, pas de VibeFlow).
- « jamais de push » → option de projet, pas une constante.
- Nommage : préfixe `vf-` partout, descriptions FR, « invocable utilisateur ET agent ».

---

## 7. Séquencement proposé

1. **D4 d'abord** (30 min) : clarifier `god-execution` vs `gsd-autonomous` pour ne pas dupliquer.
2. **5b** (boucle test+fix + 3 workers cloisonnés) : matérialise la partie la plus tangible,
   testable isolément sur un projet mobile.
3. **5a** (mode orchestration dans `vf-auto` + référence protocole) : le cerveau qui compose tout.
4. **5c** (câblage vérif visuelle) : relie 5a à `mobile-test`.
5. **Preuve** : run réel `god-execution` sur une phase à faible enjeu d'un projet mobile (projet source),
   de bout en bout, jusqu'au *done*.

---

## 8. Critère de preuve (sans lui, la brique n'est pas « faite »)

Le point le plus risqué — **un sous-agent qui invoque des skills GSD ET spawne d'autres
sous-agents en cascade** — n'est prouvé nulle part (le spec projet source dit « à valider en run réel »).
La brique 5 n'est déclarée fonctionnelle qu'après **un run réel** où `vf-auto` en mode
orchestration pilote une phase entière (plan → exécution → test réel → fix → *done*) sans
intervention, avec au moins un cycle de fix et un arrêt propre. Tant que ce run n'existe pas,
statut **expérimental**.

## 9. Risques

- **[ARCHI]** Nesting de sous-agents non prouvé dans l'env VibeFlow → tester tôt (5b isolé).
- **[DENSITÉ]** Le protocole ne doit PAS gonfler `AGENT.md` → tout en référence on-demand.
- **[REDONDANCE]** D4 non tranché → risque de réimplémenter `gsd-autonomous`.
- **[SÉCURITÉ]** Mode autonome + fix de code = HALT-3/HALT-5 obligatoires, pas optionnels.
