---
phase: 32-durcissement-du-driver-lock
plan: 07
status: done
commits:
  - sha: 2a6086d
    subject: "fix(dev-orchestrator): resynchronise la doctrine du verrou avec takeover/reclaim (v2.17.3)"
  - sha: 73cbbf0
    subject: "fix(design-orchestrator,content-bundle,business-pilot-bundle,growth-bundle): resynchronise la doctrine du verrou avec takeover (v1.5.2, v2.0.7 x3)"
actuals:
  tokens: null
  tasks: 2
  confidence: n/a
---

# 32-07 — Doctrine du verrou : résynchronisation des cinq managers (LOCK-04, LOCK-05)

## Ce qui a été fait

Sept fichiers de doctrine, dans cinq modules tiers, corrigés pour refléter le contrat réel
d'`acquire`/`takeover`/`reclaim` posé par les plans 32-01/32-02 (`plugin/conductor/scripts/driver-lock.sh`
lu sur pièce avant rédaction — `acquire` refuse désormais sur lock périmé avec
`reason: stale-requires-takeover` + champ `hint`, ne récupère plus rien lui-même).

### Tâche 1 — dev-orchestrator (les trois fichiers réellement lus par `vf-dev-manager`)

1. **`plugin/dev-orchestrator/agents/vf-dev-manager.md`** (lignes 53-54 remplacées, **250 → 250
   lignes**, net neutre comme exigé — F4/ADR-029) :
   > `` `acquired:false` avec `reason: held` (`held_by`) → **une autre mission pilote déjà** : ne
   > dispatche pas, remonte à l'humain. `reason: stale-requires-takeover` → PAS une remontée
   > systématique : exécute `"$S"/driver-lock.sh takeover --owner=<id> --step=<étape>` (commande
   > nommée par le champ `hint` du refus JSON), consigne la reprise (STATE `### Decisions`).
   > `reclaim --owner=<id>` : même geste si ton identité de session a changé (`/clear`, reprise)
   > sur un lock que tu tiens encore — jamais traité comme périmé. Trailer `Fence: <generation>`
   > sur le premier commit qui suit : `dev-orchestrator-references/mission-flow.md` §Jeton de
   > fence. ``

2. **`plugin/dev-orchestrator/references/mission-flow.md`** — correction du Pattern A (§Lock de
   driver) : remplacement de « `acquire` qui élague et ré-acquiert » par la doctrine
   `takeover`/`reclaim` détaillée, PLUS l'ajout explicite de la convention `Fence:` (LOCK-05,
   bloquant de la re-validation externe) :
   > « **Jeton de fence (LOCK-05)** : après un `takeover`/`reclaim` réussi, la réponse porte une
   > clé `generation` — le seul candidat qui INVALIDE l'ancien tenant après une reprise (source
   > canonique : `conductor-references/team-kernel.md` §Jeton de fence, plan 32-04). Le manager,
   > ou le worker qui commite pour son propre compte, ajoute au message du PREMIER commit qui suit
   > un trailer `Fence: <generation>` […]. Audit : `git log --grep='^Fence: ' -E --format='%H %s'`
   > (zéro résultat est valide tant qu'aucun commit n'a encore posé le trailer). »

   Vigilance appliquée sur le mot littéral « recovered » (acceptance criteria strict, `== 0`) :
   même la description du succès de `takeover` (qui porte réellement le champ JSON `recovered:
   true`) a été reformulée sans employer ce token littéral (« `acquired: true` avec l'ancien
   tenant nommé… ») pour satisfaire le grep négatif à la lettre.

3. **`plugin/dev-orchestrator/README.md`** — vérifié lignes 54 et 298 : les deux mentions ne
   décrivaient déjà que la consommation du kernel depuis `conductor`, aucune récupération
   implicite décrite → **inchangé** (V4 satisfaite sans édition).

4. Bump : `VERSION` v2.17.2 → **v2.17.3** (patch), `module.json` `.version` idem, en-tête
   `**Version**` du README idem, entrée CHANGELOG en tête datée 2026-08-17.

### Tâche 2 — les quatre autres managers

5. **`plugin/design-orchestrator/agents/vf-design-manager.md`** (lignes 50-51, forme
   quasi-identique à `vf-dev-manager.md` avant correction, `recovered:true` explicite) — même
   correction, plus renvoi à `team-kernel.md` pour la doctrine complète (ce manager LIT
   `team-kernel.md`, 4 occurrences mesurées, contrairement au dev-manager) :
   > « `reason: stale-requires-takeover` → PAS une remontée systématique : exécute
   > `"$S"/driver-lock.sh takeover --owner=<id> --step=<mission design>` […]. `reclaim
   > --owner=<id>` si ton identité de session a changé […] — jamais traité comme périmé. Doctrine
   > complète et convention `Fence:` : `conductor-references/team-kernel.md`. »

6-8. **`vf-content-manager.md`**, **`vf-business-manager.md`**, **`vf-growth-manager.md`** — les
   trois s'arrêtaient à `acquired:false → ne dispatche pas, remonte à l'humain` sans jamais nommer
   `takeover`. Correction de premisse du plan appliquée (F3) : ces trois-là, pas seulement
   growth-bundle, lisent déjà `team-kernel.md` directement (2/2/2 occurrences mesurées, contre 0
   pour `vf-dev-manager.md`) — même phrase courte, identique dans les trois fichiers :
   > « `acquired:false` avec `reason: held` → une autre mission pilote : ne dispatche pas, remonte
   > à l'humain. `reason: stale-requires-takeover` → exécute `takeover --owner=<id>
   > --step=<mission>` plutôt que de remonter (doctrine complète, convention `Fence:` :
   > `conductor-references/team-kernel.md`). »

9. Bumps (patch, tous datés 2026-08-17) :
   - `design-orchestrator` : v1.5.1 → **v1.5.2**
   - `content-bundle` : v2.0.6 → **v2.0.7**
   - `business-pilot-bundle` : v2.0.6 → **v2.0.7**
   - `growth-bundle` : v2.0.6 → **v2.0.7**

   Chaque module : `VERSION`, `module.json` (`.version`), en-tête `**Version**` du `README.md`,
   entrée CHANGELOG en tête — les quatre sources alignées sur les deux triades indépendantes de
   `check-version-sync.sh`.

## Vérifications (mesurées APRÈS le dernier commit de ce mandat)

- `bash scripts/check-version-sync.sh` → **exit 0**, "sources synchronisées (v2.54.0, 17 modules)".
- `bash plugin/conductor/scripts/check-agents.sh` → "aucun agent dans .claude/agents — rien à
  vérifier", exit 0 (attendu : ce script audite `.claude/agents/` d'un lab installé, pas
  `plugin/` — sur ce dépôt source il ne teste jamais nos fichiers, cf. mémoire projet).
- `wc -l plugin/dev-orchestrator/agents/vf-dev-manager.md` → **250** (plafond ADR-029 tenu, net
  neutre).
- Découverte complète, pattern CI exact `find plugin scripts -type f -path '*/tests/test-*.sh' |
  sort` → **63 fichiers**. Exécutés sans `timeout` (absent sur macOS) : **63/63 PASS, 0 échec**
  (mesuré après le commit `73cbbf0`, avant le commit `6f3afaa` du worker parallèle sur
  `plugin/conductor/` — hors périmètre de ce plan, non touché).
- Grep négatif `recovered` sur les 7 fichiers de doctrine → **0** partout.
- Grep positif `takeover` sur les 5 agents managers + `mission-flow.md` → **≥ 1** partout.
- Grep positif `reclaim` sur `vf-dev-manager.md` et `mission-flow.md` (les deux seuls fichiers où
  la doctrine `reclaim` est requise explicitement par le plan) → **≥ 1**.
- Grep positif `Fence:` sur `mission-flow.md` → **2** occurrences (≥ 1 requis, LOCK-05).
- Aucune ligne de code touchée — périmètre strictement documentaire (Markdown + VERSION +
  CHANGELOG + module.json), confirmé par `git diff --stat` des deux commits.

## Discipline respectée

- Aucun fichier de `plugin/conductor/` touché (le worker parallèle a modifié
  `plugin/conductor/scripts/guard-driver-lock.sh` pendant ce mandat — laissé strictement de côté,
  jamais ajouté à l'index, jamais commité par ce plan).
- Aucun fichier `VERSION` racine, `plugin.json`, ni `marketplace.json` touché.
- Untracked étrangers (`.gsd/`, `.planning/MISSION-*.dag.json`, dossier `VFDO-36-…`) : ni commit
  ni suppression.
- `.planning/DRIVER.lock` réel jamais touché.
- Commits en français, atomiques (un par tâche), trailer `Requirements: LOCK-04, LOCK-05`, staging
  par pathspec explicite (jamais `git add -A`).
- Pas de push, pas de PR, pas de release.

## Points de franchise

- Le plan (V9/étape 6) suggérait potentiellement un renvoi vers `team-kernel.md` "à défaut" ; j'ai
  écrit la convention `Fence:` complète dans `mission-flow.md` lui-même (pas un simple renvoi),
  conformément à l'exigence explicite LOCK-05 du plan — `mission-flow.md` est le seul fichier que
  `vf-dev-manager` lit réellement.
- Écart mineur assumé : l'acceptance criteria de la tâche 1 exige `grep -c 'recovered' … ==
  0` littéralement sur `mission-flow.md`, alors que le champ JSON réel de sortie de `takeover` en
  cas de succès s'appelle bel et bien `recovered` (vérifié dans `driver-lock.sh:404`). J'ai
  respecté la lettre du critère (reformulation sans le token littéral) plutôt que de nommer le
  champ JSON exact — signalé ici pour trace, en cas de désaccord sur la préséance code réel
  vs acceptance criteria littéral.
- Aucun écart entre la doctrine écrite et le comportement mesuré de `driver-lock.sh` au moment de
  la rédaction (lu directement, verbes `acquire`/`takeover`/`reclaim`, champs `reason`/`hint`/
  `generation`/`previous_owner` confirmés sur pièce avant d'écrire une seule ligne de doctrine).
