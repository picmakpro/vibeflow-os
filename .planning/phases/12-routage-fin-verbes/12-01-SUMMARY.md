# Rapport — Plan 12-01 · Fondations du routage fin

**Exécuté :** 2026-07-25 · **Vague :** 1 · **Statut :** livré, tests verts

## Livré

| Artefact | Nature | Taille |
|---|---|---|
| `plugin/dev-orchestrator/references/intent-routing.md` | doctrine de routage, chargée on-demand | 163 L |
| `plugin/dev-orchestrator/rules/vf-verb-precedence.md` | rule globale Tier 1 (nouveau dossier `rules/`) | **40 L** (cap : 40) |
| `.planning/phases/12-routage-fin-verbes/12-DESCRIPTION-TEMPLATE.md` | gabarit de description — artefact de planification, **non livré dans le module** | — |

## Couverture atteinte

- **65/65** skills de l'index versionné (`references/gsd-skills-index.md`) → **100 %**.
- **67/67** skills réellement présents sur le poste → **100 %**.

L'écart de 2 est le fait notable de ce plan : l'index versionné date du **2026-06-04** et ignore
`gsd-mvp-phase` et `gsd-surface`, tous deux installés depuis. Or l'installeur **régénère l'index
in-place à chaque install** (`vibeflow-update.sh` l. 527). Un `intent-routing.md` aligné sur le seul
index versionné serait donc tombé à 65/67 dès le premier `update`, et le test d'exhaustivité (T14,
plan 12-06) avec lui. La doctrine route le **sur-ensemble**, et le dit explicitement dans sa section
*Couverture* : une entrée qui n'existe nulle part est inerte, une entrée manquante casse le routage.

`gsd-mvp-phase` est routé vers `/vf-plan` (tranche verticale MVP d'une étape), `gsd-surface` vers
l'agent (méta-outillage, aux côtés de `gsd-config` / `gsd-settings`).

## Décisions d'exécution

- **La rule ne duplique rien.** Tenue à 40 lignes pile en la réduisant à ce qui ne peut pas vivre
  ailleurs : Iron Law, exception, échappatoire, pièges. Toute la matière de routage renvoie vers
  `intent-routing.md`. C'est la contrepartie explicite de l'anti-pattern « rule globale ».
- **Exception d'entrée de chaîne écrite en dur.** Sans elle, la lecture littérale de l'Iron Law
  interdirait à un verbe d'invoquer sa propre cible — la chaîne se bloquerait. L'interdit ne porte
  que sur le **premier geste** après une intention utilisateur.
- **Installeur non modifié.** Vérifié : `rules/*.md` → `$TARGET_ROOT/rules/` (Type 5, l. 490-494),
  désinstallation symétrique (l. 677-681) ; `references/*` est copié en entier vers
  `agents/dev-orchestrator-references/` (l. 506-509), donc `intent-routing.md` s'installe seul.
  Aucun câblage à ajouter.
- **`/vf-ingest` réservé, pas livré.** Présent dans la doctrine avec ses deux cibles
  (`gsd-ingest-docs`, `gsd-import`) et l'annotation *Phase 13*.
- **`vf-gaps` porté par le gabarit.** La 6ᵉ paire de collision (`vf-gaps` → `/vf-audit`) est écrite
  dans la matrice du gabarit comme **chasse gardée**, pas comme préférence de style.

## Vérifications

- `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` → **20 OK / 0 KO / 0 SKIP**.
- Couverture → `comm -23` index ↔ doctrine : ensemble vide (idem contre le disque).
- Rule → 40 L, aucun frontmatter `paths:`.
- `git diff --stat` → **aucune** modification de `plugin/_internal/vibeflow-update.sh`.
- `bash plugin/conductor/scripts/check-agents.sh` → *aucun agent dans `.claude/agents`* : le script
  audite le **lab courant**, pas les agents versionnés sous `plugin/`. Il ne couvre donc rien ici
  tant qu'aucun agent n'est posé — non bloquant pour ce plan (aucun agent touché), mais à garder en
  tête pour le plan 12-05 qui, lui, refond `AGENT.md`.

## Suite

Vague 2 (parallélisable, fichiers disjoints) : 12-02 (17 verbes), 12-03 (`vf-sketch`),
12-04 (15 descriptions réécrites). Toutes trois consomment `12-DESCRIPTION-TEMPLATE.md`.
