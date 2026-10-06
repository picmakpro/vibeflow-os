# REFERENCE — Source de vérité transverse

> Externalisée du CLAUDE.md (ADR-042). Le CLAUDE.md y pointe, ne la duplique pas.

## Vocabulaire

> Glossaire de domaine du dépôt (POCK-02, P414-D-08). Format : `terme — définition — source`. Aucune
> entrée sans source ; alimenté pendant le cadrage (`plugin/dev-orchestrator/references/docs-flow.md`
> §Famille savoir). Première passe issue du cadrage de la Phase 41.4. Chemins relatifs à la racine du dépôt.

- **compartiment** — mot surchargé, deux objets homonymes sans lien : un compartiment de planning est un workstream `.planning/workstreams/{nom}/` ; un compartiment de documentation est un dossier `docs/{projet}/` posé par le scaffold — source : `plugin/dev-orchestrator/references/workstreams.md` (en-tête) ; `plugin/conductor/scripts/scaffold-docs.sh` (« Bornes et vocabulaire »).
- **revue** — mot surchargé : la revue de diff de code (`vf-reviewer`, nœud `revue-N`) n'est pas la revue cross-AI de plans amont (`gsd-review`) ; deux étages disjoints — source : `plugin/dev-orchestrator/references/mission-contracts.md` §Étage revue, `docs/ADR.md` ADR-061.
- **frontière de questions** — au cadrage, l'ensemble des décisions encore ouvertes, posées en un tour numéroté, une recommandation par question ; cadrage terminé quand elle est vide — source : `plugin/dev-orchestrator/references/mission-flow.md` §Pattern F (POCK-01).
- **frontière de phase** — point de sortie d'un geste ou d'une mission où le head choisit continuer, clear, handoff, sous-agent ou compact (dans cet ordre) — source : `plugin/dev-orchestrator/references/head-governance.md` §3 (POCK-03).
- **axe Standards / axe Spec** — les deux axes de la revue de diff : conventions du dépôt d'un côté, conformité au PLAN de l'étape de l'autre ; le nœud ne passe que si les deux passent — source : `plugin/dev-orchestrator/agents/vf-reviewer.md` (revue à deux axes) ; `plugin/dev-orchestrator/references/mission-contracts.md` §Deux axes de revue : Standards et Spec (POCK-04).
- **merge-danger call** — section obligatoire du corps de PR : porte à sens unique ou à double sens, et rayon d'explosion du merge — source : `plugin/dev-orchestrator/references/mission-contracts.md` §Isolation de branche (POCK-06) ; contrôlée par E3 de `plugin/dev-orchestrator/scripts/check-mission-exit.sh`.
- **classe d'invocation** — classement d'un skill en user-invoked (déclenché par l'humain seul) ou model-invoked, déclaré par le champ `vf-invocation` et vérifié par machine — source : `plugin/conductor/scripts/check-skills.sh` (en-tête, « Classe d'invocation », POCK-07).
- **défaillance observée** — troisième segment obligatoire du trailer `Ajout-Retrait:` : la session, le geste ou le commit daté où le manque a été constaté — source : `plugin/conductor/scripts/check-ajout-retrait.sh` (en-tête, POCK-08).
- **sain / manque / indéterminé** — les trois issues du gate de sortie de mission, codes 3 / 0 / 4 ; seul « sain » (3) signifie vérifié et conforme, un indéterminé n'est jamais un vert — source : `plugin/dev-orchestrator/scripts/check-mission-exit.sh` (en-tête).
- **gate / garde** — un gate est un contrôle machine à trois issues avec mutation rouge prouvée (QUAL-01) ; une garde in-repo (G-1 à G-3) rend visible et trace sans verrouiller — source : `CLAUDE.md` § Gardes in-repo ; `docs/ADR.md` ADR-072.

## Conventions

Renvoi : `CLAUDE.md` du dépôt, § Conventions transverses, fait foi — aucune copie ici.

## Stack / contraintes communes

Renvoi : `CLAUDE.md` du dépôt, § Conventions transverses, fait foi — aucune copie ici.
