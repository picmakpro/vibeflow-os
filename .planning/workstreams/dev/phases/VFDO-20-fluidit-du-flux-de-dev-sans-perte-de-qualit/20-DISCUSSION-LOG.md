# Phase 20: Fluidité du flux de dev sans perte de qualité - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-28
**Phase:** 20-Fluidité du flux de dev sans perte de qualité
**Mode:** `--auto` (assumptions), sans `AskUserQuestion`
**Areas discussed:** Changement 1 (MCP fin `vf-reviewer`), Critère 2 (écart tools/runtime),
Changement 2 (revue premier rang), Changement 3 (`.planning/MISSION-INVARIANTS.md`), Changement 5 /
ROADMAP Changement 4 (scope hooks + bug charset MCP), Gouvernance/release.

---

## Note de méthode

`vf-dev-manager` a mandaté `vf-coder` pour produire ce cadrage en **cadrage seul, sans exécution**
(checkpoint humain prévu avant tout plan d'exécution). `vf-coder` n'a pas `AskUserQuestion` dans son
allowlist — cohérent avec la doctrine que ce cadrage documente lui-même (D-09 de CONTEXT.md). Les
4 décisions de doctrine du digest de mission (D1→D4, tranchées par Samuel le 2026-07-28 dans
`.planning/missions/2026-07-28-phase-20-instruction-prealable.md`) ont été appliquées **sans
re-question** — elles ne figurent pas ci-dessous comme « discutées », seulement comme des contraintes
appliquées. Ce qui est journalisé ci-dessous, c'est la résolution des gray areas d'**implémentation**
que ces 4 décisions laissaient ouvertes, découvertes par l'agent `gsd-assumptions-analyzer` dispatché
en amont.

## Changement 1 — accès MCP fin de `vf-reviewer`

| Gray area | Option retenue | Alternative écartée |
|---|---|---|
| Mécanisme d'injection des 3 tools nommés | Nouveau mode dédié dans `inject-mcp-tools.sh`, spécifique à `vf-reviewer`, injectant 3 tokens nommés d'UN serveur identifié | Réutiliser `vf-mcp-consumer: true` tel quel — écarté : ce mécanisme injecte le wildcard-serveur ENTIER pour CHAQUE serveur du `.mcp.json`, violerait la granularité fine de D-01 |
| Révision ADR-051 | Carve-out ciblé pour `vf-reviewer` seul, `vf-dev-manager`/`vf-auditer` inchangés | Réviser toute la clause de moindre privilège — écarté, hors mandat de Samuel |

**[auto] Sélection :** nouveau mode d'injection nommé (recommandé, motif : seule option qui respecte
à la fois D-01 (granularité fine) et la philosophie ADR-051 « dérivée du lab » sans risque de
sur-privilège si le lab a d'autres serveurs MCP configurés).

**Signalé au manager (pas tranché en silence) :** le nom exact du marqueur de frontmatter reste un
degré de liberté d'implémentation — cf. D-05/Claude's Discretion de CONTEXT.md.

## Critère 2 — écart `tools:`/runtime, sens fermeture

| Gray area | Option retenue | Alternative écartée |
|---|---|---|
| Où documenter le constat "AskUserQuestion peut être absent en sous-agent" | `team-kernel.md` (à côté de la restriction `Agent(...)` déjà documentée ligne 23, même famille) + filet de repli dans `vf-dev-manager.md` | Créer une nouvelle référence dédiée — écarté, `team-kernel.md` est déjà le point de vérité pour ce type de constat runtime |
| Forme du filet de repli | Copier la phrase déjà écrite dans `vf-coder.md` (patron existant, prouvé fonctionner dans cette mission même) | Écrire une formulation neuve — écarté, réutiliser un patron déjà validé réduit le risque de divergence |

**[auto] Sélection :** documentation dans `team-kernel.md` + copie du patron `vf-coder.md` (recommandé,
motif : le patron existe déjà et cette mission même en est la preuve vivante — `vf-coder` l'a suivi
pour produire ce cadrage sans planter).

## Changement 2 — revue de premier rang

| Gray area | Option retenue | Alternative écartée |
|---|---|---|
| Le cycle de `vf-coder` garde-t-il un filet de revue interne ? | Non — la revue sort intégralement, cycle réduit à 3 étapes (Cadrage/Plan/Exécution) | Garder une revue interne "de secours" pour les missions hors DAG manager — écarté : `vf-coder` est décrit comme "dispatché UNIQUEMENT par un manager du team-kernel", donc le manager pose systématiquement `revue-N` |
| Déclenchement de la revue de jointure | Topologie du DAG (paire de nœuds `exec` incomparables → descendant `join`) | Intersection des périmètres de fichiers — écarté explicitement par Samuel (vide par construction en parallélisation nominale) |

**[auto] Sélection :** cycle `vf-coder` réduit à 3 étapes (confirmé par le texte même du ROADMAP :
"la revue est en dur à l'étape 4… défaut de placement, pas de doctrine").

**Signalé au manager :** ce changement modifie le fichier `vf-coder.md` lui-même — l'agent qui produit
ce cadrage. Pas de contradiction logique, mais à noter pour la revue du plan.

## Changement 3 — `.planning/MISSION-INVARIANTS.md`

| Gray area | Option retenue | Alternative écartée |
|---|---|---|
| Forme des "motifs de risque récurrents" | Zones de risque en globs (falsifiables, patron CODEOWNERS) | Prose narrative libre — écartée par D4 lui-même (invérifiable machine) |
| Table des fichiers gelés — stockage | Convention documentée, dérivée à la demande de `dag.sh --scope` sur le(s) DAG(s) actif(s) | Copie statique périodiquement mise à jour à la main — écartée explicitement (risque de péremption mensongère, précédent cité par Samuel) |
| "Contrainte d'outillage du moment" (4e item du critère 5 littéral) | Inclure dans une section explicitement étiquetée "non gaté" | Exclure entièrement (cohérence stricte avec le principe D4) / Inclure sans étiquette (fidélité au texte littéral du critère 5) |

**[auto] Sélection :** inclusion étiquetée "non gaté" (recommandé — concilie le texte littéral du
critère 5 avec le principe de D4 sans mentir sur le niveau de garantie).

**Signalé au manager (Unclear, résolu par défaut mais à valider) :** cette 3e option n'est écrite
noir sur blanc nulle part dans le digest de mission — c'est une interprétation de `vf-coder` pour
concilier un texte de critère à 4 items avec un principe de décision qui n'en garantit explicitement
que 2. Voir D-16 de CONTEXT.md.

## Changement 5 (ROADMAP Changement 4) — scope hooks

| Gray area | Option retenue | Alternative écartée |
|---|---|---|
| Comment concilier "silencieux en nominal" et "utile sur dérives" (critère 6) | Affichage conditionné au compte réel de warnings (`if warning_count > 0`) | Lever l'exemption `--hook` inconditionnellement — écarté, romprait le silence nominal voulu par conception |
| Bug de charset MCP (`check-agents.sh:355` vs `inject-mcp-tools.sh`) | Intégré au périmètre de cette phase, fix ciblé du regex (accepter `*` final après `mcp__<serveur>__`) | Justifier son exclusion — écarté, le digest demandait explicitement de l'intégrer ou de justifier, et l'intégration est peu coûteuse et cohérente avec le périmètre déjà touché par Changement 1 |
| Validation de la forme complète des tokens MCP (corollaire) | Hors périmètre, Claude's Discretion / Deferred | Élargir le fix pour valider toute la forme `mcp__<serveur>__<outil>` — écarté, non requis par les 7 critères, risque de dérive de scope |

**[auto] Sélection :** affichage conditionné au compte (recommandé, seule option qui satisfait
littéralement les deux moitiés du critère 6).

## Claude's Discretion

- Découpage exact en N fichiers `20-NN-PLAN.md`.
- Nom exact du marqueur de frontmatter pour l'injection MCP nommée de `vf-reviewer`.
- Forme exacte du regex du bug de charset.
- Emplacement exact du script de détection de "zone morte" (`MISSION-INVARIANTS.md`).
- Étendue exacte de la relecture de `team-kernel.md`/`conductor/README.md` au-delà des lignes citées.
- Si le Changement 5 mérite son propre ADR ou reste un CHANGELOG.

## Deferred Ideas

- Recette humaine sur lab iOS avec XcodeBuildMCP réellement connecté (validation des noms d'outils
  exacts `test_sim`/`build_sim`/`clean`).
- Resserrer la validation de forme des tokens MCP au-delà de l'acceptation du `*` final.
- Vérifier l'affirmation "anti-triche vérifié par les suites de test de chaque module"
  (`team-kernel.md:23`) — non re-vérifiée dans ce cadrage.
- Retrait de `Bash` sur `vf-design-judge` — écarté au profit d'une documentation honnête de l'angle
  mort.
