# HANDOFF — clôture d'`equipe-produit-v1.0` et ouverture du jalon « V2 »

**Date** : 2026-10-29 · **Auteur** : session principale (Samuel + Claude), avant `/clear`.
**Arbitrage** : Samuel, session principale, 2026-10-29 — « ajoute ça en nouvelle phase dans la
nouvelle milestone ; clore la milestone en cours ; sinon note de takeover/handoff ».
**Statut** : rien n'est encore clos ni créé dans `.planning/`. Ce document est l'entrée du geste.

## Pourquoi un handoff plutôt que le geste

Au moment d'écrire : une autre session fait tourner des agents sur les issues GitHub (worktrees
`.claude/worktrees/issues-A..D`, branches `fix/issues-lot-A..D`, 0 commit chacune à 23h50) ; la
session qui écrit va être effacée (`/clear`) ; et surtout **le jalon en cours n'est pas finissable
à la main** : la Phase 59 est exécutée mais pas mergée (voir § 2). Clore un jalon avec une phase
livrée-non-mergée et trois phases non commencées est une décision, pas un rangement.

## 1. État du planning (compartiment `fiabilite`, mesuré)

| Objet | État |
|---|---|
| Verrous `driver-lock.sh status --all` | dépôt, `fiabilite`, `gouvernance` : **libres** (takeover + release manuels du 2026-10-29, 2 orphelins fermés `stopped`) |
| Jalon ouvert | `equipe-produit-v1.0` — « l'équipe produit » (Phases 57-62) |
| Phase 57 | livrée, release `v2.70.0` |
| Phase 58 | livrée, releases `v2.71.0` → `v2.71.2` |
| **Phase 59** | **exécutée sur `feat/phase-59-bundle-produit` (worktree `.claude/worktrees/phase-59`, tête `ad0fbbf7`)** : plans 59-01..07 cochés, revue-59 F2..F6 corrigées, PRDT-01..12 cochées sur preuve, « arrêt avant merge (P59-PL-21) ». Le manager est mort APRÈS, à l'étape `mission`. **Il manque : PR, merge, release.** |
| Phases 60, 61, 62 | non commencées |
| Jalon `ecc-inspiration-v1.0` (51-56) | inscrit, non commencé, « après clôture de fiabilite-v1.0 » |
| Jalon `gouvernance-labs-v1.0` (42-50) | compartiment `gouvernance`, Willy |

## 2. Ordre proposé pour la session qui reprend

1. **Finir la 59** avant tout : relire `59-*-SUMMARY.md` et le ledger sur la branche, ouvrir la PR
   depuis `feat/phase-59-bundle-produit`, relecture adverse SOBR-04, merge, release **minor**
   (`v2.72.0`, tag + release GitHub, gate `check-release-tag.sh --remote`). Geste humain gaté :
   demander le `/gsd-ship` et la release à Samuel, jamais les inférer.
2. **Trancher le sort de 60-62** avec Samuel (AskUserQuestion, une seule question) :
   (a) les reporter dans V2, (b) les laisser en BACKLOG, (c) finir le jalon d'abord. L'intention
   exprimée le 2026-10-29 penche vers (a) ou (b) : « clore maintenant ».
3. **Clore `equipe-produit-v1.0`** par `/gsd-complete-milestone`. Piège connu : `--archive roadmap`
   retire les en-têtes de phase et laisse `check-divergence` rouge (S4(a)) tant que les dossiers de
   phases restent — voir mémoire `archive-roadmap-casse-check-divergence`.
4. **Créer V2** par `/gsd-new-milestone` avec ce document en entrée (`gsd-ingest-docs --mode merge`
   le proposera au démarrage). Spec § 3.
5. Le sort d'`ecc-inspiration-v1.0` se décide au même moment : fusionner ses phases utiles dans V2
   ou le laisser inscrit derrière.

## 3. Le jalon V2 — proposition

**Nom** (convention `<slug>-vX.Y`) : `vibeflow-v2.0` — « l'upgrade majeur ». Alternatives :
`upgrade-v2.0`, `v2-concret`. Samuel : « V2 c'est pas mal ».

**Milestone Goal** : un saut d'usage très concret pour qui installe VibeFlow — ce qu'on voit, ce
qu'on touche, ce qui ne casse plus — plutôt que de la doctrine. Chaque phase livre une capacité
visible dans une release.

**Phase 1 (première du jalon) — « vf-signal : le cockpit, fiabilisé et pour tout le monde »**

- **Goal** : le mod `vf-signal` (pane cockpit : mission en DAG par vagues, arbre des agents en
  direct, vue macro phase → jalon → projet → backlog, refus des gardes, prochaine action humaine,
  bandeau) est **embarqué dans le plugin `vibeflow`** et livré dans une release. Entre-temps il se
  teste et s'améliore depuis `~/.claude/mods/vf-signal` (marketplace local `vf-mods`, scope user).
- **Source du code** : `~/.claude/mods/vf-signal/` — 11 fichiers, `claude plugin validate` ✔,
  `tsc` ✔ (strict), `claude plugin test` 3/3 sur 4 surfaces. Design : VibeFlow Media v2 « Signal »
  (cyan = machine, orange = humain). Règle : le mod observe et affiche, les hooks décident.
- **Ce qu'il faut trancher au cadrage** :
  1. Le plugin `vibeflow` n'a **aucun hooks module** aujourd'hui (pas de `plugin/hooks/hooks.json` ;
     ses hooks sont des hooks commande par module, posés dans les settings par l'engine). Un mod se
     déclare au niveau du plugin et se charge pour quiconque l'installe, **hors toggles** → gating
     par module (marqueur posé par l'installeur, lu par le mod) ou toujours actif ?
  2. Emplacement : module conventionnel `plugin/vf-signal/` (VERSION, module.json, CHANGELOG,
     README) + `plugin/hooks/hooks.json` → `modules: ["../vf-signal/hooks/register.tsx"]` ; le
     chemin `../` est à prouver par `claude plugin validate plugin/`.
  3. L'API des mods est « early access, peut changer entre releases » : prévoir une suite CI
     (`validate` + `test` du mod) et une sortie propre quand l'engine refuse le module.
  4. `driver-lock.sh` est cherché dans `.claude/scripts/`, `plugin/conductor/scripts/`,
     `~/.claude/scripts/` : vérifier les deux scopes d'install (user / project).
  5. Mobile : dessine (Box/Text/Button), toujours compact, `$.ui.copy` inerte, pas de hotkeys.
  6. Contraintes : ADR-035 (300 lignes, déjà respecté), ADR-029 n/a, ADR-031 (aucune action
     agent ; les boutons sont humains : recover, takeover copié, compacter, arrêt demandé par
     message), SOBR-04 à la release. Release **minor**.
- **Requirements candidats** (famille `VFSG`) : VFSG-01 embarqué et chargé à l'install ;
  VFSG-02 gating ; VFSG-03 suite CI validate+test ; VFSG-04 recette terminal plein écran / inline /
  VS Code / mobile ; VFSG-05 manuel (page FR/EN) ; VFSG-06 release taguée.
- **Mémoire utile** : `mod-vf-signal-regles-validateur` (5 règles du validateur qui coûtent une
  itération chacune), `vf-signal-a-embarquer-dans-vibeflow`.

**Phases candidates suivantes** (à arbitrer, pas inscrites) : 60-62 reportées si (a) au § 2 ;
phases utiles d'`ecc-inspiration-v1.0` ; améliorations du cockpit nées de l'usage.

## 4. Garde-fous pour qui reprend

- `driver-lock.sh status --all` avant tout checkout dans l'arbre principal ; sinon worktree.
- Ne jamais supprimer les worktrees `issues-A..D` ni `phase-59` : ils appartiennent à des missions
  d'autres sessions (lots d'issues en cours ; 59 à merger).
- `state record-session` et `state.planned-phase` réécrivent STATE.md : sauvegarde + diff.
- Une release = tag annoté + release GitHub + `check-release-tag.sh --remote` ✓, après SOBR-04.
