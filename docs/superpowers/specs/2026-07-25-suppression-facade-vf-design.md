# Spec — Suppression de la façade vf-* et bascule vers le modèle agentique

**Date** : 2026-07-25 · **Décideur** : Samuel (arbitrage direct, audit vague 2)
**Contexte** : audit croisé du 2026-07-25 — la couche de 31 verbes vf-* double un catalogue
gsd-*/superpowers qui reste exposé en session ; la concurrence de routage que la façade
prétend résoudre est celle qu'elle crée (table de routage ×4, 122 renvois négatifs, rule de
préséance en prose, boilerplate reframe ×30).

## Décision (verbatim de l'arbitrage)

> « Supprimer l'appel aux vf-* qui sont juste la façade. On garde le vf-dev-manager qui
> s'occupe lui d'appeler les sous-agents qui eux ont accès à toutes les features de GSD —
> un agent par thème avec plusieurs commandes gsd allouées ; les agents coder, reviewer etc.
> perdurent. Le manager a toute l'intelligence pour savoir qui appeler en fonction de ce
> qu'il détecte de la volonté de l'utilisateur. Il fait aussi des propositions de next step
> avec GSD, il sait quand mettre à jour les specs, la doc, le planning. Bref un modèle
> agentique optimisé, pas une façade miroir de GSD. Les termes du vocabulaire GSD peuvent
> apparaître — la règle de reframe saute. »

## Architecture cible

### Ce qui est SUPPRIMÉ

- **Les 31 skills vf-*** de `plugin/dev-orchestrator/skills/` — sauf exceptions ci-dessous.
  GSD (gsd-*) redevient l'interface directe du quotidien : ses descriptions déclenchent
  nativement, sans couche de synonymes.
- **La rule `vf-verb-precedence`** (préséance prose contre prose) et le boilerplate
  « Reframe / Ne nomme jamais GSD » des skills.
- **`vocabulary-map.md`** comme obligation de traduction (peut rester comme glossaire doc).
- **Le skill `/vf-dev`** en tant que table de routage dupliquée → réduit à 3 lignes
  « incarne l'agent vibeflow-dev ».
- Les matrices de renvois négatifs ✘ croisés entre descriptions (n'ont plus d'objet).

### Ce qui est CONSERVÉ (logique réelle, pas façade)

| Brique | Rôle conservé |
|---|---|
| `vf-auto` (skill) | Porte d'autonomie : seuil SEUIL_EQUIPE, aiguillage gsd-autonomous inline vs équipe |
| Agent `vibeflow-dev` | Entrée conversationnelle optionnelle — détecte l'intention, invoque les gsd-* directement, propose l'équipe sur signal mission (ADR-046 DM4) |
| Agent `vf-dev-manager` | Cerveau de mission (voir upgrade ci-dessous) |
| Agents `vf-coder` / `vf-reviewer` / `vf-auditer` | Équipe thématique — chacun avec accès DIRECT aux briques gsd de son thème (plus de wrapper 1:1 : vf-reviewer PILOTE la revue via gsd-code-reviewer et agrège, il n'est plus une simple enveloppe) |
| Équipe mobile (`vf-test-*`, `vf-app-fixer`) | Inchangée (cloisonnement anti-triche = garde-fou) |
| `references/` (mission-flow, mission-contracts, guardrails, GSD-PIPELINE) | Doctrine de l'équipe |
| `scripts/` (dag.sh, driver-lock.sh) + tests | Kernel d'orchestration (extrait en V3) |
| Verbes conductor (`/vf-audit`, `/vf-update`, `/vf-new-lab`, `/vf-planning`, `/vibeflow`) | Hors périmètre — gouvernance, pas façade dev |

### Upgrade du manager (« toute l'intelligence »)

`vf-dev-manager` gagne trois capacités :

1. **Détection d'intention** : le brief peut être du langage naturel brut ; le manager mappe
   lui-même vers les étages/briques gsd pertinents (la table vit dans UNE référence :
   `intent-routing.md` refondu, seule source).
2. **Next steps** : à chaque fin d'étape et de mission, propose la suite depuis
   ROADMAP/STATE (reprend le rôle de gsd-progress au niveau mission).
3. **Hygiène documentaire** : sait QUAND déclencher gsd-docs-update, la mise à jour
   des specs (.planning/phases/), STATE/ROADMAP — critères explicites (fin d'étape,
   décision structurante, drift détecté), pas de mise à jour au fil de l'eau.

### Logique à réloger avant suppression des verbes

| Verbe supprimé | Logique à réloger | Destination |
|---|---|---|
| vf-debug | Pré-étape recherche doc ADR-045 | Rule `doc-research-before-debug` (existe déjà) + heuristique agent |
| vf-gaps | Multiplex des 3 cibles d'audit | Heuristique de l'agent vibeflow-dev |
| vf-decide | Exception panel en mission | Déjà documentée (commit c71c69f) |
| vf-progress | Routage d'intention libre | gsd-progress natif + next-steps du manager |
| vf-quick/vf-execute | Frontière trivial/structurant | Heuristique de l'agent (gsd-quick vs gsd-execute-phase) |

## Migration (ordre)

1. Refondre `intent-routing.md` : de « table des 31 verbes » à « carte intention → brique
   gsd / équipe » (seule source, consommée par les 2 agents).
2. Upgrader `vf-dev-manager.md` + `AGENT.md` (vibeflow-dev) : suppression des références aux
   verbes, ajout détection d'intention / next steps / hygiène doc.
3. Supprimer les 30 skills (tout sauf vf-auto), réduire vf-dev, retirer la rule de préséance.
4. Adapter les tests (T1-T14) : les tests de collision de descriptions deviennent des tests
   de la carte d'intention ; garder densité, cloisonnement, exhaustivité contre l'index.
5. Mettre à jour module.json / README ×2 / marketplace (« 31 verbes » → modèle agentique),
   CHANGELOG du module, bump **major** du module dev-orchestrator (2.0.0).

## Conséquences assumées

- Les utilisateurs qui tapaient `/vf-plan` etc. utilisent gsd-* directement ou parlent à
  l'agent en langage naturel. `/vf-auto` reste le raccourci d'autonomie.
- Le vocabulaire GSD apparaît dans les sorties (fin du reframe) — assumé.
- La doc marketing (README) bascule de « 31 verbes » à « orchestration agentique ».
