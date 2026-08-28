---
name: vf-calibrate
description: Utiliser quand le framework VibeFlow a évolué et qu'un lab doit être remis à niveau — « mets à jour VibeFlow », « le framework a bougé », « recalibre mon lab », « est-ce que ma structure est à jour ? », ou quand le surfaçage d'ouverture de session signale un retard. Détecte l'écart de version framework ↔ lab, lit les changements (dont structure/doctrine), propose une migration, et la pilote SOUS validation humaine. ✘ pas pour **installer** une version plus récente du plugin et des modules (le geste « télécharge et pose la nouvelle version ») → /vf-update · ✘ pas pour créer un lab qui n'existe pas encore → /vf-new-lab · ✘ pas pour auditer la conformité méthodologique d'un lab déjà à niveau → /vf-audit. Invocable par l'utilisateur ET par `vibeflow-conductor`.
---

# vf-calibrate — Propagation d'update & migration de lab

> **Mission** : faire en sorte qu'un lab installé **voie** les évolutions du framework et soit
> **recalibré proprement** — y compris quand la *structure* ou la *doctrine* change (pas juste des
> fichiers de module).
>
> **Iron Law** : *« Détecter et proposer la migration ; jamais l'appliquer sans validation humaine. »*
> (ADR-031 — une migration de doctrine peut casser des rules contextuelles.)

---

## Pourquoi ce skill existe

Un `vibeflow-update.sh update` réécrit des fichiers de module. Ça suffit pour un bugfix, **pas** pour
une évolution de **structure/doctrine** (nouveau principe, nouveau registre, restructuration) — là, le
lab doit être **migré**, pas écrasé. Ce skill comble ce trou et reproduit l'effet GSD : *l'utilisateur
voit que le framework a bougé et son lab se recalibre*.

## Séquence

### 1. Détecter l'écart

```sh
.claude/scripts/framework-version.sh drift
```

Compare la version framework enregistrée dans le lab (`.claude/.vibeflow-framework-version`) à la
version courante du plugin. 3 cas :
- **À jour** → rien à faire (le confirmer).
- **Retard mineur (PATCH/MINOR)** → modules à rafraîchir, pas de migration structurelle.
- **Retard majeur (MAJOR)** ou changement de doctrine → **migration** requise (étape 3).

### 2. Lire ce qui a changé

Lire les `CHANGELOG.md` des modules concernés + l'historique du framework. **Classer** chaque
changement : *bugfix / nouvelle capacité / **breaking-doctrine*** (structure, registres, principes).
Détail dans `references/migration-playbook.md`.

> **Cas planning v2 (compartiments)** — si planning-core passe en v2 (topologie *steering lab + plan
> conditionnel typé*), c'est un *breaking-doctrine* : appliquer la **recette §2bis** du
> `migration-playbook.md` (détection de dette via `detect-planning-debt.sh` → typage deliverable/
> continuous → récupération de l'existant en `_archive/` → désengorgement mémoire → `INDEX.md`).
> **Sans perte de données** : on promeut ou on archive, jamais on supprime.

### 3. Proposer un plan de migration (jamais l'appliquer en silence)

Pour les changements **structure/doctrine**, produire un plan explicite :
- ce qui change dans le lab (fichiers, registres, conventions),
- ce qui est **réversible** (snapshot avant) vs ce qui demande une décision,
- les rules contextuelles potentiellement impactées (risque de casse).

**Présenter le plan à l'utilisateur. Attendre son feu vert.** (ADR-031.)

### 4. Appliquer sous contrôle

1. **Snapshot avant** (le lab est sauvegardé).
2. Rafraîchir les modules — **plan avant pose (MANI-02, issue #20)** : d'abord
   `VIBEFLOW_CACHE="${CLAUDE_PLUGIN_ROOT}" bash "${CLAUDE_PLUGIN_ROOT}/_internal/vibeflow-update.sh" --dry-run update <module>`,
   dont la sortie (stdout, le plan fichier-par-fichier) est montrée à l'utilisateur — c'est le
   contenu du plan de migration déjà présenté à l'étape 3, pas un second feu vert. `--dry-run`
   n'écrit rien et est refusé sur `uninstall`. Puis rafraîchir réellement, inchangé :
   `VIBEFLOW_CACHE="${CLAUDE_PLUGIN_ROOT}" bash "${CLAUDE_PLUGIN_ROOT}/_internal/vibeflow-update.sh" update <module>` (manuel, par module).
3. **Ré-affirmer l'allowlist MCP des agents exécutants** (ADR-051) : si le lab a gagné (ou perdu)
   un serveur MCP — dans son `./.mcp.json` (scope projet) **ou** en scope global `~/.claude.json`
   (union des deux sources depuis Phase 21, ADR-051-B — un serveur déclaré seulement en scope
   global, cas courant sur ce parc, déclenche désormais aussi la ré-affirmation) — **sans** bump de
   module (l'`update` ne re-copie pas les agents à version inchangée), re-jouer l'injection
   idempotente sur les agents flaggés `vf-mcp-consumer` :
   ```sh
   .claude/scripts/inject-mcp-tools.sh --target .claude/agents --mcp-json ./.mcp.json
   ```
   Le scope global (`--claude-json`, défaut `$HOME/.claude.json`) est lu automatiquement en plus —
   aucun flag supplémentaire requis dans l'appel ci-dessus, sauf pour cibler un fichier de test.
   Et, si GSD est présent, ré-affirmer aussi `gsd-executor` (relancer `.claude/scripts/ensure-deps.sh` suffit — il
   appelle le patch, ou directement `.claude/scripts/inject-mcp-tools.sh --target ~/.claude/agents/gsd-executor.md
   --mcp-json ./.mcp.json --force`). **Redémarrage de Claude Code requis** ensuite : le `tools:` des
   agents est lu au démarrage de session.
4. Appliquer la migration structurelle validée (déléguer au migrateur / `software-architecture`
   `/restructure` si réorganisation de fichiers).
5. **Re-stamper** la version framework : `bash .claude/scripts/framework-version.sh stamp`.
6. **Re-auditer** : déléguer à `vibeflow-validator` (5 phases) pour confirmer l'alignement.

### 5. Synthèse

Rapport court : ce qui a été migré, ce qui reste, prochain audit conseillé.

---

## Surfaçage à l'ouverture de session (opt-in)

`.claude/scripts/framework-version.sh drift --quiet` est conçu pour un **hook SessionStart opt-in** : il
signale *« le framework a pris de l'avance, lance /vf-calibrate »* sans rien forcer (`|| true`,
jamais bloquant). Wiring documenté dans `references/migration-playbook.md` — **jamais auto-injecté**
dans `settings.json` (respect du principe « zéro hook imposé »).

---

## Garde-fous

- **Jamais d'auto-migration / auto-update** sans validation humaine (ADR-031).
- **Toujours snapshot avant** toute migration structurelle.
- **Toujours re-stamper + re-auditer** après migration (sinon drift fantôme).
- **Distinguer bugfix vs doctrine** : ne pas traiter une restructuration comme un simple `cp`.
- **Côté maintenance VibeFlow** : ce skill est l'outil par lequel l'équipe peut recalibrer un lab
  branché en suivant la dernière version — toujours via le même garde-fou de validation.

## Références (on-demand)

- `references/migration-playbook.md` — classification des changements + recettes de migration + wiring hook.
- `.claude/scripts/framework-version.sh` (matérialisé dans le lab à l'install) — current / recorded / stamp / drift.
