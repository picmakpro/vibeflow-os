# CLAUDE.md — vibeflow-os

Guidance pour Claude Code quand il travaille **sur ce repo** (le repo de distribution du plugin
VibeFlow, pas un lab qui l'installe).

## Ce qu'est ce repo

Marketplace + plugin Claude Code à **modules toggables** sous `plugin/`. Chaque module a son
`VERSION`, son `module.json`, son `CHANGELOG.md`, son `README.md`. L'engine d'install scopé vit
dans `plugin/_internal/vibeflow-update.sh`. La doc méthodologique de référence (Core, patterns) est
dans `plugin/reference/`. Le socle de gouvernance est le module `conductor`.

## Règle non négociable — Discipline de release : toute version = un tag

> **Toute release (bump de la `VERSION` racine) DOIT créer et pousser un tag git annoté `vX.Y.Z`
> pointant sur le commit de release.**

Une version sans tag n'est ni traçable ni installable par référence. C'est précisément ce qui a
fait diverger `main` en juillet 2026 : v2.10.0 → v2.16.0 publiées sans jamais être taggées, états
intermédiaires irretrouvables.

**À chaque release :**

1. **Bump cohérent** du même numéro dans les trois fichiers : `VERSION`,
   `plugin/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` — plus l'historique des
   deux README (`README.md` **et** `README.fr.md`, badges inclus).
2. **Après le merge sur `main`**, crée et pousse le tag annoté :
   ```bash
   git tag -a vX.Y.Z -m "vX.Y.Z — <résumé>" <commit-de-release>
   git push origin vX.Y.Z
   ```
3. **Crée la release GitHub** sur le tag (titre court, notes = résumé du tag + commits couverts) :
   ```bash
   gh release create vX.Y.Z --title "vX.Y.Z — <résumé court>" --notes "<résumé + liste des commits depuis le tag précédent>" --verify-tag
   ```
   Un tag sans release GitHub rend la page Releases mensongère — c'est ce qui s'est produit de
   v2.29.0 à v2.39.0 (14 versions taggées, page bloquée sur v2.28.0, rattrapage le 2026-07-26).
4. **Vérifie** : `bash scripts/check-release-tag.sh --remote` → doit sortir `✓` (le gate vérifie
   le tag local, le tag poussé **et** la release GitHub).

**Garde-fou machine** : `scripts/check-release-tag.sh` échoue (exit 1) si la `VERSION` courante n'a
pas son tag. Câblage `pre-push` optionnel (bloque uniquement les push vers `main`) :
`git config core.hooksPath scripts/hooks` (une seule fois par clone).

**Numérotation** : `vMAJOR.MINOR.PATCH`. Nouveau module / nouvelle capacité → **minor** ;
correctif / doc / durcissement → **patch**. Le tag reprend **exactement** la valeur de `VERSION`
(préfixe `v` inclus).

## Conventions transverses

- **Densité** (ADR-029) : agents ≤ 250 lignes, skills ≤ 500, bootstrap ≤ 2000 tokens.
- **Jamais de fix sans validation humaine** (ADR-031).
- **Agents natifs machine-enforced** (ADR-044) : tout agent posé passe `plugin/conductor/scripts/check-agents.sh`
  (description + model + memory requis). Un worker **interne** (dispatché uniquement par un
  orchestrateur) déclare `vf-internal: true` → pas de commande d'incarnation exposée (Pattern 12).
- **Commits** : messages en français, cohérents avec l'historique du repo.
