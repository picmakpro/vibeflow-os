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

**Quand publier** : une release ne se déclenche **que pour une évolution fonctionnelle de
VibeFlow** — un comportement qui change dans ce qu'un utilisateur installe. Une PR qui ne porte que
de la documentation, des specs ou du planning (`docs/`, `.planning/`, mémoire d'agents) se merge
**sans release** : sinon les utilisateurs reçoivent une mise à jour qui ne contient rien. Ces
changements partent avec la prochaine release fonctionnelle. Doctrine complète et motif :
`docs/ADR.md` § **ADR-073** (arbitrage Samuel, AskUserQuestion session principale, 2026-09-23) ;
inscrite ici à la demande de Willy (WhatsApp, 2026-09-23). Non gatée par machine : c'est au geste de
release de la tenir.

**Numérotation** : `vMAJOR.MINOR.PATCH`. Nouveau module / nouvelle capacité → **minor** ;
correctif / durcissement → **patch**. Le tag reprend **exactement** la valeur de `VERSION`
(préfixe `v` inclus).

## Conventions transverses

- **Densité** (ADR-029) : agents — avertissement dès 251 lignes, bloque au-delà de 300 ; skills ≤ 500, bootstrap ≤ 2000 tokens.
- **Jamais de fix sans validation humaine** (ADR-031).
- **Agents natifs machine-enforced** (ADR-044) : tout agent posé passe `plugin/conductor/scripts/check-agents.sh`
  (description + model + memory requis). Un worker **interne** (dispatché uniquement par un
  orchestrateur) déclare `vf-internal: true` → pas de commande d'incarnation exposée (Pattern 12).
- **Commits** : messages en français, cohérents avec l'historique du repo.
- **Traçabilité des arbitrages** : un commit qui invoque une décision humaine nomme le **canal et la
  date** — « arbitrage Samuel, AskUserQuestion session principale, 2026-09-09 ». Un simple
  « arbitrage Samuel » a la même forme qu'il soit vrai ou fabriqué : c'est le lecteur d'après qui
  paie. Adoptée le 2026-09-10, née du commit `8fc4b45` (Phase 39), dont personne ne pouvait vérifier
  l'attribution — un manager a dû remonter la chaîne pour l'établir.

## Gardes in-repo — ce qui est gardé, ce qui ne l'est pas

`main` n'est protégée par aucune règle côté serveur — aucun accès admin sur ce dépôt (ADR-072) —
donc les gardes ci-dessous rendent visible et tracent, elles ne verrouillent rien.

- `scripts/check-baseline-arbitrage.sh` (G-1) : rougit sur une hausse de la colonne des
  instructions de la baseline du budget d'instructions, ou sur une sentinelle d'armement
  neutralisée, sans citation d'arbitrage conforme dans le commit qui porte le changement.
- `scripts/check-gate-touche.sh` (G-2) : rougit quand un gate, sa suite, `.github/workflows/ci.yml`
  ou un hook sont touchés sans marqueur déclaratif dans un commit de la branche.
- `scripts/check-push-sans-pr.sh` (G-3) : alarme après coup, un commit arrivé sur `main` sans PR
  associée — quand elle rougit, le commit est déjà sur `main`.

**Marqueur** : tout commit qui touche un gate, sa suite, le workflow CI ou un hook porte un trailer
`Gate-Touche: <chemin-ou-motif> — <raison>`. Déclaratif — forme et présence vérifiées, jamais la
véracité de la raison — de portée branche : un commit ultérieur peut couvrir un chemin touché plus
tôt.

**Baseline** : toute hausse d'une valeur de la baseline du budget d'instructions exige, dans le
commit qui la fait, une citation d'arbitrage avec son canal et sa date — la convention de
traçabilité déjà énoncée plus haut dans ce fichier.

**Limite de fond** : une garde qui vit dans le dépôt peut être modifiée par la PR qu'elle juge.
Détail complet : ADR-072.
