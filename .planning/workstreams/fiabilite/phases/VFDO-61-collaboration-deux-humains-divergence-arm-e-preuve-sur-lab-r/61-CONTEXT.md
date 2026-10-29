# Phase 61: Collaboration à deux humains — divergence armée, preuve sur lab réel - Context

**Gathered:** 2026-10-29
**Status:** Ready for planning

Cadrage porté par `vf-dev-manager` (mission-flow §Pattern F), **sans humain joignable** : mandat Samuel,
/vf-auto session principale, 2026-10-29 (« reprends le handoff et va jusqu'au bout […] Fini les phases
du jalon sans moi »). Ce mandat ne vaut pas arbitrage de fond : **aucune décision de ce fichier n'est un
arbitrage neuf.** Chacune est un défaut écrit dans une source citée, ou une hypothèse retenue faute de
réponse (`P61-H-xx`), ou un **bloqueur humain** (`P61-B-xx`) qui n'empêche pas le plan mais empêche de
cocher l'exigence qui en dépend.

- Faits établis d'abord par un éclaireur en lecture seule sur la branche 59 (rapport du 2026-10-29,
  repris en `<code_context>`).

**Exigences :** famille `COLB`, réservée le 2026-10-08, vérifiée libre le 2026-10-29 (`git grep 'COLB-'`
rc=1 sur la branche et sur `main`, `git log --all -S'COLB-'` vide). Posée à l'ouverture de la
planification. **L'exigence de preuve sur lab réel (critère 4 du jalon) est posée et reste décochée**
tant que P61-B-01 et P61-B-02 ne sont pas levés : la phase livre le mécanisme, sa preuve automatisée sur
clones jetables, et la procédure de recette ; elle ne simule jamais la preuve humaine.

<domain>
## Phase Boundary

1. **Divergence armée par défaut pour un lab multi-humains** (spec §5.3, H-06) : à l'installation avec
   un poste d'équipe, le clone reçoit un hook git `post-merge` qui joue `check-divergence.sh` après chaque
   fusion locale, crie sur une divergence, et la **journalise** (spec §9 critère 4 : « chaque divergence
   détectée par `check-divergence.sh`, journalisée »).
2. **Champ `role:` des registres** (spec §5.3, H-07) : DECISIONS, LEARNINGS, BLOCKERS portent le poste de
   qui a écrit l'entrée, « rien de plus ».
3. **Preuve** : (a) preuve de mécanisme automatisée, deux clones jetables d'un même dépôt, même machine
   (SEED A-03) ; (b) procédure de recette pour la preuve d'usage — deux humains, deux clones, deux rôles,
   un workstream, trois semaines sur un lab réel (ROADMAP 61, spec §8 point 2, §9 critère 4) — exécutée
   par des humains, hors de cette mission.

Hors de cette phase : un workstream par rôle (spec §5.3, deux vérités) ; tout contrôle d'accès ; la
modification de `scripts/hooks/` ou d'une sentinelle `.planning/.*-armed` de CE dépôt (CODEOWNERS ;
l'armement vit dans les labs, posé par l'installeur).

</domain>

<decisions>
## Implementation Decisions

### Armement

- **P61-D-01 (qui arme, où).** Source : spec §5.3 (« hook `post-merge` armé par défaut pour ce profil ») ;
  mémoire de lab « armement sans précondition distribuée » (un réglage posé à la main ne voyage pas,
  l'armement passe par l'installeur) ; éclaireur §2 (`role_apply()` de `vibeflow-update.sh` est le seul
  point où l'installeur agit selon le poste). L'installeur arme le clone dans `role_apply()` (ou à côté),
  et désarme proprement quand le poste repasse à `solo` ou à la désinstallation.
- **P61-D-02 (jamais écraser un hook de l'utilisateur).** Source : ADR-031 (aucune action non validée sur
  ce qui appartient à l'humain) ; pratique de l'engine (fusion des fragments, jamais remplacement). Pas de
  `core.hooksPath` (il désactiverait tous les hooks existants du clone, husky compris) ; un `post-merge`
  existant qui n'est pas le nôtre n'est ni écrasé ni modifié : l'armement est alors refusé **audiblement**
  (message et code), avec la ligne à ajouter à la main. Forme exacte (hook dans le répertoire de hooks
  réel du clone, `git rev-parse --git-path hooks`, worktrees compris) au choix du planificateur.
- **P61-D-03 (le hook n'exécute jamais du code que la fusion vient d'apporter).** Source : arbitrage
  Samuel, AskUserQuestion session principale, 2026-09-10 (`scripts/hooks/post-merge:14-27`, résolution
  anti-RCE) ; audit M-2 de l'engine (`vibeflow-update.sh:1268-1274` : jamais d'exécution de
  `$TARGET_ROOT/scripts`, résolution par le cache du plugin). Dans un lab, l'exécutable
  `check-divergence.sh` est résolu hors de l'arbre versionné (cache du plugin installé), jamais depuis
  `.claude/scripts/` du lab ni depuis `--show-toplevel`. Le répertoire INSPECTÉ reste le worktree courant.
  Introuvable → silence audible (non vérifiable), jamais un faux « conforme ».
- **P61-D-04 (branchement sur les codes, journal).** Source : `scripts/hooks/post-merge:34-46` (1 → crie,
  0/3 → silence, autre → non vérifiable sans bloquer ; un post-merge ne peut pas annuler la fusion) ; spec
  §9 critère 4 (« journalisée »). Chaque exécution non silencieuse (divergence, non vérifiable) ajoute une
  ligne horodatée à un journal **non versionné**, propre au clone (sous le répertoire git commun, comme le
  verrou de driver) — jamais un fichier suivi qui créerait lui-même des conflits entre clones. Format
  stable et lisible par la procédure de recette.
- **P61-D-05 (pull --rebase).** Source : ADR-069 amendement 4 (`docs/ADR.md:2340-2352` : `post-merge` ne
  voit pas tout). Le planificateur mesure si `post-rewrite` doit doubler `post-merge` pour couvrir
  `git pull --rebase` ; s'il ne le fait pas, la limite est écrite dans la doc, pas tue.
- **P61-D-06 (sortie).** Source : spec §5.4 (« non-interactif préservé ») ; ADR-031. Un opt-out explicite
  et documenté existe (variable d'environnement ou option de l'installeur), lu à chaque install.

### Registres

- **P61-D-07 (champ `role:`).** Source : spec §5.3 H-07 (« ajouter le champ `role:` sur une entrée pour
  savoir qui a décidé, rien de plus ») ; éclaireur §3 (format existant `**Champ** : valeur`, gabarits SYNC
  à deux emplacements : `plugin/reference/content/methodology/templates/memory/` source, copies
  `plugin/consolidator/references/templates-memoire/`). Le champ suit le format existant des entrées,
  valeur lue par `vf-role.sh get` (jamais relue à la main ; codes 1/5/64 jamais repliés sur `solo`).
  Optionnel en lecture : une entrée ancienne sans le champ reste valide pour tous les parseurs
  (`check-registres`, `reindex`, `archive`, `detect-duplicates`, `detect-promotions`), prouvé par suite.
  Source modifiée d'abord, copies ensuite (règle SYNC).

### Preuve

- **P61-D-08 (preuve de mécanisme automatisée).** Source : SEED A-03 (« lab jetable, deux clones, même
  machine. Prouve le mécanisme, pas l'usage ») ; mémoire « une preuve doit pouvoir rendre rouge ». Une
  suite découverte par la CI crée un dépôt partitionné jetable, deux clones armés **par le vrai chemin
  d'installation**, fait diverger la numérotation d'un compartiment sur les deux clones, fusionne par un
  vrai `git pull`/`git merge`, et constate : hook déclenché, divergence criée, ligne de journal écrite.
  Témoin rouge exigé (hook désarmé ou exécutable muté → la suite rougit). Aucun nom de client.
- **P61-D-09 (procédure de recette du lab réel).** Source : ROADMAP 61 (« lab réel, pas un clone
  jetable ») ; spec §9 critère 4. Un document de recette dans le dossier de phase : prérequis (deux
  humains, deux clones, postes `product` et `dev`, un workstream), armement, relevé hebdomadaire des
  journaux des deux clones, critère de passage (trois semaines, aucune divergence subie en silence :
  toute divergence observée dans l'historique git est présente au journal), gabarit de compte rendu.
  L'exigence correspondante reste **décochée**.
- **P61-D-10 (gates et livraison).** Source : QUAL-01, ADR-071, ADR-054, critères 5-6 du jalon, P60-D-09
  (aucune hausse de baseline d'instructions sans arbitrage), P60-D-10 (aucun skill neuf), 59-08 (porte
  rejouée depuis `ci.yml`, arrêt avant PR/merge/tag/release). Trailer `Gate-Touche` sur tout commit qui
  touche `check-divergence.sh`, une suite ou une fixture surveillée. Manuel FR+EN. Release minor décidée
  par le manager après merge (CLAUDE.md : nouvelle capacité).

### Hypothèses retenues faute de réponse (à faire confirmer par Samuel)

- **P61-H-01 (« lab multi-humains » = poste d'équipe).** Le clone est armé quand l'installeur pose un
  poste `product` ou `dev` ; jamais au poste `solo` (critère 2 du jalon, non-régression). Motif : aucun
  signal « multi-humains » n'existe (éclaireur §2) ; le poste est déclaré par chaque humain, et l'armement
  est de toute façon par clone. La clé `vf_roles` de `.planning/config.json` n'est pas retenue comme
  déclencheur (éditée à la main, absente de la plupart des labs).

### Bloqueurs humains (n'empêchent pas le plan, empêchent de cocher la preuve)

- **P61-B-01 (lab de la preuve).** Quel lab réel, avec quels deux humains ? Décision de Samuel (spec Q-10 ;
  P59-D-11 renvoie déjà « un lab désigné par Samuel » pour le run produit).
- **P61-B-02 (durée).** Trois semaines d'usage réel après armement : ne peut pas se produire dans une
  mission. Déclencheur de clôture proposé : compte rendu de recette déposé dans le dossier de phase.

</decisions>

<canonical_refs>
## Canonical References

- `docs/superpowers/specs/2026-09-16-equipe-produit-bmad-design.md` — §5.3, §5.4, §8, §9 critère 4, §11 A-03
- `.planning/seeds/SEED-001-equipe-produit-v1.md` — A-03, A-11
- `docs/ADR.md` — ADR-031, ADR-054, ADR-069 (risque (d), amendement 4), ADR-071
- `plugin/conductor/scripts/check-divergence.sh` (codes 0/1/2/3/64), `scripts/hooks/post-merge` (référence de branchement, à ne pas modifier)
- `plugin/_internal/vibeflow-update.sh` — `role_apply()` (~l.1331-1357), audit M-2 (~l.1268-1274)
- `plugin/conductor/scripts/vf-role.sh`
- `plugin/reference/content/methodology/templates/memory/` (source) ; `plugin/consolidator/references/templates-memoire/` (copies) ; `plugin/consolidator/scripts/` (parseurs)
- Phase 39 (archivée sous `.planning/milestones/fiabilite-v1.0-phases/VFDO-39-*`) — 39-01-SUMMARY (hook armé sur dépôt jetable, `GATE_FIRED`), 39-03-SUMMARY (un clone, deux workers)

</canonical_refs>

<code_context>
## Existing Code Insights

- L'engine ne pose aujourd'hui **aucun** hook git ni sentinelle (`git grep 'post-merge|hooksPath'` rc=1 sous `plugin/_internal/`).
- Le poste n'est posé qu'en scope projet (en scope user, toujours `solo`) ; sous `--target`, aucun fichier n'est posé.
- `test-check-divergence.sh` ne fait ni clone ni merge : aucune suite n'exerce un hook `post-merge` aujourd'hui.
- Commentaire périmé `check-divergence.sh:61-62` (« exit 3 = état nominal de ce dépôt ») : à corriger si la phase touche le fichier.

</code_context>

<deferred>
## Deferred Ideas

- Preuve d'usage sur lab réel (P61-B-01, P61-B-02).
- Confirmation de P61-H-01 par Samuel.

</deferred>
