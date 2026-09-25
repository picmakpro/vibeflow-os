# Phase 42: Fabrique — manifeste daté et invariants de doctrine du gate des agents - Context

**Gathered:** 2026-09-23
**Status:** Ready for planning

> **Mode de cadrage.** Zones grises présentées à Willy (AskUserQuestion session principale,
> 2026-09-23), qui a répondu « tranche tout, tu as de quoi ». **Toutes les décisions ci-dessous
> sont donc des décisions de Claude**, prises sur mesures faites dans la session, et doivent être
> lues comme telles. Aucune n'est un arbitrage humain ; celles qui touchent un autre propriétaire
> (Samuel) le disent.

<domain>
## Phase Boundary

Le gate des agents `plugin/conductor/scripts/check-agents.sh` cesse de porter ses listes de
référence en dur : il les lit dans un **manifeste daté** versionné, et un manifeste périmé ne
peut plus produire un verdict favorable. Le gate gagne les **invariants de doctrine I1 à I7** de la
spec de la fabrique, et sa **découverte des agents devient récursive**. Les agents du corpus sont
mis en conformité pour que la CI, qui passe `--strict` sur tous les `plugin/*/agents`, reste verte.

**Dans le périmètre** : fabrique §1.1 (lignes 2 à 4 — outils manquants, champs `KNOWN` manquants,
test qui verrouille une affirmation périmée), §1.2, §1.3, §3, §4 (I1-I7 + découverte récursive).

**Hors périmètre** : I8 et le correctif des blueprints (PR #85, déjà écrite) ; le gate des skills
et l'unification MCP (Phase 43) ; le hook central par rôle (Phase 45) ; tout §8 de la spec
(`skills:`, `cacheTtl`, `maxTurns`, `color:`).

</domain>

<decisions>
## Implementation Decisions

### Le manifeste daté
- **D-01 : un fichier de données versionné à côté du gate** (`plugin/conductor/scripts/`, format
  JSON, lisible par le Python déjà embarqué). Il porte les six listes (identifiants d'outils, champs
  de frontmatter connus, types d'agents natifs, modèles, modes de permission, niveaux d'effort) et,
  **pour chaque liste**, `verifie_le` (date ISO) et `source` (URL de la doc officielle lue). Le
  script ne garde **aucune** copie de repli des listes : une seule vérité (même principe que
  `check-blueprints.sh`, qui délègue au gate au lieu de réimplémenter).
  — **Reversibility:** costly — le format est lu par le gate, `check-blueprints.sh`, `guard-agent-write.sh` (indirectement) et la CI ; le changer ensuite touche tous ces lecteurs.
- **D-02 : validité de 30 jours**, portée par le manifeste lui-même (`valide_jours: 30`), jamais
  par le script. Mesure qui fonde le choix : les commentaires datés du 2026-07-05 et du 2026-07-27
  ont laissé passer 6 identifiants d'outils et 2 champs en moins de deux mois.
- **D-03 : un fichier manifeste absent ou illisible est un refus explicite** (exit ≠ 0 avec
  diagnostic), jamais une liste vide qui laisserait tout passer.

### Ce que fait un manifeste périmé — là où il est tenu, et là où il ne l'est pas
- **D-04 : l'INDÉTERMINÉ (exit 3) n'est rendu que là où l'on peut rafraîchir le manifeste**, c'est-à-dire
  dans la CI du dépôt, par une option explicite passée par les étapes CI. Chez un utilisateur
  (garde d'écriture `guard-agent-write.sh`, hook `SessionStart --hook`), un manifeste périmé
  produit un **avertissement**, jamais un refus.
  Fait mesuré qui l'impose : `guard-agent-write.sh` refuse l'écriture dès que le gate imprime un
  diagnostic `✗`. Un INDÉTERMINÉ par défaut bloquerait **toute écriture d'agent** dans tout lab
  installé depuis plus de 30 jours, et l'utilisateur n'a aucun moyen de rafraîchir un manifeste
  livré par le plugin.
  — **Reversibility:** reversible.
- **D-05 : un manifeste périmé ne peut plus refuser sur une liste fermée.** Quand le manifeste est
  périmé, les erreurs « outil inconnu », « champ inconnu » et « type natif inconnu » sont
  rétrogradées en avertissement dans tous les contextes. Ailleurs, elles gardent leur régime
  actuel. C'est le principe de la spec (« un gate qui ne sait plus si sa référence est à jour n'a
  pas le droit de rendre un verdict »), appliqué dans les deux sens : il n'a pas plus le droit de
  refuser que d'accepter. C'est ce qui ferme le défaut §1.1 n° 2 : un agent légitime refusé en
  `--strict` à cause d'une liste en retard.

### Les invariants — définitions retenues
- **D-06 :** I1 se lit sur le marqueur `Worker interne` dans `description:`. Mesuré : les
  19 agents `vf-internal: true` le portent tous, et aucun agent non interne ne le porte. Le gate
  vérifie la corrélation dans les deux sens.
- **D-07 : un « manager » au sens d'I6 = porteur d'un `Agent(...)` non vide ET non `vf-internal`.**
  La définition de la spec (« porteur d'un `Agent(...)` non vide ») est trop large. Mesuré : elle
  classe manager `vf-reviewer`, `vf-auditer` et `vf-coder`, des workers internes qui dispatchent
  des briques `gsd-*`. **Écart assumé par rapport à la spec §4.**
- **D-08 :** un « juge » au sens d'I5 = `disallowedTools` qui retire `Write` et `Edit` ET aucun
  `Agent(...)`. Dans la définition de la spec, `omitClaudeMd: true` tomberait aussi sur
  `vf-reviewer` et `vf-auditer`, qui ont besoin des conventions du projet pour relire. Exiger
  qu'ils l'ignorent casserait leur fonction. Avec cette définition, les juges visés sont 4 :
  `quality-gate-client`, `content-clarity-judge`, `growth-quality-judge`, `vf-design-judge`.
  **Écart assumé par rapport à la spec §4.** À vérifier par la recherche : la sémantique exacte de
  `omitClaudeMd` dans la doc officielle (charge-t-il encore les règles `.claude/rules/` ? le
  `CLAUDE.md` utilisateur ?).
- **D-09 : I2 et I3 réutilisent le monde fermé existant.** Aucun registre écrit à la main : la
  liste des dispatchés se dérive des allowlists `Agent(...)` de l'union des agents, exactement
  comme l'étape CI `--resolve-agents=strict` (avec les `--agent-registry-dir` répétés). I2 et I3
  ne s'activent que sous `--resolve-agents=strict`.
- **D-10 : la découverte récursive exclut explicitement ce qui n'est pas un agent.** Elle ne doit
  pas prendre un `README.md` ou un fichier de contenu pour un agent. La règle d'exclusion est
  vérifiée par un cas de test.

### La mise en conformité du corpus
- **D-11 : les invariants sont armés en erreur, et le corpus est corrigé dans cette phase.** Pas de
  période d'avertissement : la CI passe déjà `--strict` sur tous les agents, et un invariant en
  avertissement est exactement la dérive que la spec combat (25 avertissements `skills:` que plus
  personne ne lit). Violations mesurées le 2026-09-23, après D-07 et D-08 :
  - I3 : `vf-test-orchestrator` (mobile-test-team) — dispatché par `vf-dev-manager`, sans `vf-internal` ;
  - I5 : les 4 juges de D-08 ;
  - I6 : `vf-business-manager`, `vf-content-manager`, `vf-growth-manager`, `vf-design-manager`, et
    `vf-test-orchestrator` si le correctif I3 le laisse porteur d'un `Agent(...)` (à trancher par le
    planificateur au vu du fichier) ;
  - I1, I2, I4, I7 : **zéro violation**.
- **D-12 :** un commit par module touché, séparé des commits du gate, avec le bump de patch du
  module (VERSION, CHANGELOG). `mobile-test-team`, `dev-orchestrator` et `design-orchestrator`
  sont de la polarité de Samuel : la PR le nomme en relecteur de ces commits-là, et le cadrage le
  consigne ici plutôt que de le découvrir en revue.
- **D-13 [informational] : sans objet — constaté par la recherche du 2026-09-23.** T76 (le test
  que la fabrique §1.1 ligne 4 disait périmé) a été corrigé par le hotfix v2.63.2 le 2026-09-17,
  cinq jours avant la spec ; il passe contre le `team-kernel.md` réel. Aucune tâche ne doit le viser.
- **D-16 : le manifeste est copié chez l'utilisateur dans la même vague qu'il est posé.**
  Constat de recherche : `copy_module_scripts()` de `plugin/_internal/vibeflow-update.sh` ne copie
  que `*.sh`/`*.mjs`/`*.js` et `*.txt` — un manifeste `.json` ne serait copié nulle part, et D-03
  refuserait alors partout. Le glob est étendu et la copie prouvée par un lab frais.
- **D-17 : les identifiants d'outils réellement manquants sont 3, pas 6** (`ListAgents`,
  `SendFeedback`, `SubagentHandback`) ; `BashOutput` et `KillShell` sont d'anciens noms déjà
  couverts (`TaskOutput`, alias de `TaskStop`), `SlashCommand` n'est dans aucune doc officielle.
  Le manifeste ne s'aligne que sur la doc officielle citée, jamais sur la liste de la spec.

### Revue de Samuel — WhatsApp, 2026-09-23 (validation humaine et trois ajouts)
Samuel a relu les décisions qui touchent sa polarité et en fait des décisions **validées par un
humain**, plus seulement prises par Claude : le passage de `vf-test-orchestrator` en `vf-internal`
(il a vérifié qu'aucun skill ni aucune commande ne l'incarne, rien ne disparaît côté utilisateur),
`omitClaudeMd` sur les 4 juges (« ils jugent contre une rubrique, pas contre les conventions du
repo »), `SendMessage` sur les 4 managers (« `vf-design-manager` n'a que AskUserQuestion, qui
n'existe pas en sous-agent : il est muet aujourd'hui »). D-07, D-08 et D-11 sont donc ratifiées
(Samuel, WhatsApp, 2026-09-23).
- **D-18 : la description de `vf-test-orchestrator` nomme ses deux dispatcheurs réels,
  `vf-dev-manager` ET `vf-auto`** (`plugin/dev-orchestrator/skills/vf-auto/SKILL.md:75` le
  dispatche vraiment). Sans cela, la formule « dispatché uniquement par le manager » rend ce second
  dispatch illégitime sur le papier. Demande de Samuel, WhatsApp, 2026-09-23. L'invariant I1 (D-06)
  doit tolérer cette formulation à deux dispatcheurs.
- **D-19 : l'effet d'`omitClaudeMd` sur `.claude/rules/*.md` se MESURE, il ne se déduit pas.** La
  recherche l'a inféré du silence de la documentation (`42-RESEARCH.md`) : c'est exactement le
  genre de déduction qui a déjà coûté cher à ce dépôt. Une tâche de la phase pose un agent de test
  avec le champ, qui rapporte s'il a reçu une règle témoin de `.claude/rules/`, et le verdict est
  consigné avant qu'I5 ne soit armé. Si les règles sont omises aussi, D-08 est réexaminée avec
  Samuel. Demande de Samuel, WhatsApp, 2026-09-23 ; complète D-08.
- **D-20 : le faux vert de l'invocation nue est fermé dans cette phase.** `check-agents.sh` sans
  argument sort `exit 0` (« aucun agent dans .claude/agents — rien a verifier ») sur ce dépôt, où
  `.claude/agents` est absent, alors que c'est l'invocation que prescrivent des critères
  d'acceptation (`.planning/codebase/CONCERNS.md:349`, sévérité MEDIUM). La phase réécrit ce gate :
  elle embarque le correctif (INDÉTERMINÉ, exit 3, sur cible absente hors `--hook`, dans l'esprit de
  F13). Signalé par Samuel, WhatsApp, 2026-09-23.
- **Conséquence pour l'exécution** : les six plans ont été écrits avant D-18 à D-20. Ils doivent être
  **révisés** (révision du planificateur puis vérificateur frais) avant `gsd-execute-phase 42` ; le
  contrôle de couverture des décisions refusera sinon de marquer la phase planifiée.

### Ordre avec la PR #85
- **D-14 : on planifie maintenant et on exécute depuis `main` après le merge de la #85.** Le plan
  pose le merge de la #85 comme précondition de sa première vague. Sa CI est rouge sur G-2
  (`check-gate-touche.sh`) faute de trailer `Gate-Touche:`. La correction appartient à cette PR,
  pas à la phase.
- **D-15 :** tout commit de la phase qui touche le gate, sa suite, `ci.yml` ou un hook porte le
  trailer `Gate-Touche:` (CLAUDE.md, G-2). C'est précisément ce qui a mis la #85 au rouge.

### Exigences proposées (à graver au ledger par le planificateur)
- **FABR-01** manifeste daté, source unique des listes ; absent = refus (D-01, D-03).
- **FABR-02** fraîcheur : INDÉTERMINÉ en CI, avertissement chez l'utilisateur, jamais de refus sur liste fermée périmée (D-02, D-04, D-05).
- **FABR-03** invariants I1-I7, définitions D-06 à D-09, chacun avec un jumeau négatif (mutation prouvée rouge).
- **FABR-04** découverte récursive avec exclusions testées (D-10).
- **FABR-05** corpus conforme sous `--strict` et `--resolve-agents=strict` (D-11, D-12) ; T76 sans objet (D-13).

### Claude's Discretion
- Nom et emplacement exact du fichier manifeste, nom de l'option CI de fraîcheur.
- Découpage en plans et en vagues.
- Forme des messages de diagnostic, dans le respect du contrat de sortie existant (0 / 1 / 3, silence de code sous `--hook`, jamais silence de message).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Specs du chantier
- `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` — spec source : §1 (diagnostic), §3 (manifeste daté), §4 (invariants), B-01.
- `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` §5.1 — contraintes transverses des gates (refus par `permissionDecision: deny`, fail-closed déclaré, faux refus mesurés dans les deux sens).

### Le gate et ce qui l'appelle
- `plugin/conductor/scripts/check-agents.sh` — le gate ; listes en dur l.169-206, contrat de sortie en en-tête (0/1/3, F13).
- `plugin/conductor/scripts/tests/test-check-agents.sh` — 82 cas, mutation sur l'arbre réel ; T76 l.1398-1434.
- `plugin/conductor/scripts/guard-agent-write.sh` — refuse dès qu'un diagnostic `✗` sort (fonde D-04).
- `plugin/conductor/hooks/hooks.json` l.22 — appel `--hook` au SessionStart.
- `.github/workflows/ci.yml` l.252-320 — trois étapes `check-agents` (par module, mono-agent, monde fermé) ; l.1300 agents installés.
- PR #85 (`fix/blueprints-conformite-gate`) — `check-blueprints.sh` et I8, précondition (D-14).

### Doctrine du dépôt
- `CLAUDE.md` — ADR-029 (densité), ADR-044 (agents natifs machine-enforced), Pattern 12 (`vf-internal`), gardes G-1/G-2/G-3 et trailer `Gate-Touche:`, traçabilité des arbitrages.
- `plugin/conductor/conductor-references/team-kernel.md` — invariants du kernel, managers et workers.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Le monde fermé `--resolve-agents=strict` + `--agent-registry-dir` : il porte déjà l'univers des agents dont I2/I3 ont besoin (D-09).
- Le contrat INDÉTERMINÉ (exit 3, F13) et `--allow-empty` : le même vocabulaire sert la fraîcheur du manifeste.
- `check-blueprints.sh` (PR #85) : il matérialise un frontmatter et le soumet au gate. Il profite du manifeste sans rien changer.

### Established Patterns
- Chaque gate a sa suite `*/tests/test-*.sh`, découverte par le balayage CI. Un jumeau négatif par règle, avec mutation prouvée par `cmp`.
- `python3` embarqué dans le bash, repli `python`, `WindowsApps` écarté (portabilité Windows).
- Silence de code sous `--hook` (exit 0), jamais silence de message.

### Integration Points
- Trois étapes CI de `check-agents` + l'étape des agents installés : c'est là qu'on passe l'option de fraîcheur (D-04).
- L'installeur copie le script dans `.claude/scripts/` des labs : le manifeste doit être copié avec lui, sinon D-03 refuse partout. **À vérifier par la recherche dans `plugin/_internal/vibeflow-update.sh`.**

</code_context>

<specifics>
## Specific Ideas

- Le manifeste doit nommer sa source par liste, pour que le rafraîchissement soit un geste vérifiable (relire l'URL, comparer, re-dater) et pas un changement de date à l'aveugle.
- La recherche doit dire s'il existe une source **lisible par machine** de la liste des outils et des champs (types du SDK, schéma publié). Si oui, le rafraîchissement peut devenir un diff outillé ; sinon, il reste un geste humain daté.

</specifics>

<deferred>
## Deferred Ideas

- Promouvoir l'avertissement « `skills:` absent » en erreur : arbitrage sur 25 agents, fabrique §8, hors phase.
- Un rafraîchissement automatique du manifeste (tâche planifiée qui ouvre une PR) : à envisager après la recherche sur la source lisible par machine.
- Unification `vf-mcp-consumer` / `vf-mcp-tools` : Phase 43.

</deferred>

---

*Phase: 42-fabrique-manifeste-date-et-invariants-de-doctrine-du-gate-des-agents*
