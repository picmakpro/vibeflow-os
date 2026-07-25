# Règle — Préséance des verbes VibeFlow (vf-verb-precedence)

> Rule **globale (Tier 1)** : **pas de `paths:`**. Une intention n'a pas de chemin de fichier —
> elle est inscopable par construction. Tenue courte à dessein (Pattern 05).

## ADR Applicables
- **ADR-029** (densité) : cette rule renvoie, elle ne duplique aucune table de routage.

## Iron Law

**Toute intention de développement entre dans la chaîne par un verbe `/vf-*` — jamais autrement.**

Les skills `gsd-*` et `superpowers:*` sont de la **plomberie interne** : jamais invoqués en entrée
de chaîne, jamais nommés à l'utilisateur. Un verbe est la **seule** source de vérité de son
intention ; l'appeler en direct court-circuite ses garde-fous, son cadrage et son reframe.

## Exception explicite

Un verbe `/vf-*` **invoque évidemment sa cible interne** — c'est précisément son rôle, et un agent
déjà incarné poursuit sa délégation normalement. L'interdit porte sur l'invocation **en entrée de
chaîne** : le premier geste après une intention utilisateur.

## Échappatoire cadrée

Aucun verbe ne couvre l'intention ? **Incarner l'agent `vibeflow-dev`**, qui consulte
`.claude/agents/dev-orchestrator-references/intent-routing.md` (routage exhaustif, chargé
on-demand) et délègue depuis là. Jamais d'appel direct « en passant ».

## Pièges Connus

- **« C'est plus rapide en direct »** — c'est plus rapide et ça saute le cadrage, la recette et le
  reframe. Le gain de trois secondes coûte une étape non vérifiée.
- **Fuite de plomberie** — annoncer « je lance `gsd-execute-phase` » : le nom interne ne sort
  jamais. Reframe via `vocabulary-map.md`.
- **Verbe inventé** — s'il n'existe pas, c'est l'échappatoire ci-dessus, pas une improvisation.

## Voir aussi
- `dev-orchestrator` → `references/intent-routing.md` (quelle intention vers quel verbe)
- `dev-orchestrator` → `references/vocabulary-map.md` (reframe des sorties)
- `reference/content/methodology/patterns/05-regles.md` (mécanique des rules)
