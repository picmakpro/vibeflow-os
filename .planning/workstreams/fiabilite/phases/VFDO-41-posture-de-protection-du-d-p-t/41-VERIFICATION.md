---
phase: VFDO-41-posture-de-protection-du-d-p-t
verified: 2026-09-18T16:46:49Z
status: passed
score: 4/4 must-haves du périmètre recadré vérifiés (G-1, G-2, G-3, doctrine)
scope_note: "Vérification du périmètre RECADRÉ sans droits admin GitHub (option (a), arbitrage
  Samuel, AskUserQuestion session principale, 2026-09-17). Les critères de succès 1, 2 et 3 du
  ROADMAP original (rulesets côté serveur) sont explicitement HORS PÉRIMÈTRE de ce verdict —
  ils sont vérifiés ici comme correctement NOMMÉS et TRACÉS comme inatteignables, pas comme
  atteints."
covered_files:
  - scripts/check-baseline-arbitrage.sh
  - scripts/check-gate-touche.sh
  - scripts/check-push-sans-pr.sh
  - scripts/tests/test-check-baseline-arbitrage.sh
  - scripts/tests/test-check-gate-touche.sh
  - scripts/tests/test-check-push-sans-pr.sh
  - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/tools/check-aucune-fermeture.sh
  - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/tools/check-trace-arbitrage.sh
  - .github/workflows/ci.yml
  - docs/ADR.md
  - CLAUDE.md
  - .planning/BACKLOG.md
  - .planning/REQUIREMENTS.md
  - .planning/phases/VFDO-25-budget-d-instructions-et-tage-d-alignement-court/25-SECURITY.md
  - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-PREUVES.md
  - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-14-SUMMARY.md
  - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-15-SUMMARY.md
  - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-16-SUMMARY.md
  - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-17-SUMMARY.md
  - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-18-SUMMARY.md
  - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-19-SUMMARY.md
incident:
  - "ERREUR DU VÉRIFICATEUR (pas de la phase) : une mutation réelle de test sur G-1 a été committée
    puis annulée par `git reset --hard`, ce qui a effacé une modification NON commitée
    préexistante de `.claude/agent-memory/vf-reviewer/MEMORY.md` (jamais stagée, donc sans objet
    git récupérable). Le fichier untracked
    `.claude/agent-memory/vf-reviewer/feedback_bash-gate-bug-classes-phase41.md` est intact.
    Signalé pour action humaine — aucune récupération possible depuis git (reflog, fsck, autres
    worktrees vérifiés, tous sans la version modifiée)."
gaps: []
human_verification: []
---

# Phase 41 : Posture de protection du dépôt — Vérification (périmètre recadré sans admin)

**Portée vérifiée :** le périmètre RECADRÉ le 2026-09-17 (option (a), arbitrage Samuel,
AskUserQuestion session principale) — quatre gardes documentées dans la demande de vérification
(G-1, G-2, G-3, doctrine), aucune protection côté serveur GitHub (impossible sans accès admin,
constat mesuré et non contesté). Ce rapport NE VÉRIFIE PAS les critères de succès 1-3 du ROADMAP
d'origine (rulesets, refus de merge, rejeu du flux de release sous une règle serveur) : leur
inatteignabilité est elle-même l'objet du point 4 ci-dessous.

**Verdict global : ATTEINT** (pour le périmètre recadré). Les trois gardes sont réellement câblées
en CI, prouvées capables de rougir ET de verdir par des mutations réelles exécutées par ce
vérificateur (pas seulement par les suites internes), et aucun livrable ne déclare de risque
« fermé ». Les critères inatteignables sans admin sont nommés comme tels et déférés au BACKLOG avec
un déclencheur de reprise explicite. Un écart mineur de documentation (SUMMARY 41-16 périmé sur un
compte de mutants) et le report de la mise à jour ROADMAP/STATE sont à noter mais ne remettent pas
en cause le verdict. Les deux jobs CI (`gates` et `tests`) ont été rejoués intégralement par ce
vérificateur et sont verts (rc=0), confirmant les chiffres cités par la phase.

**Incident à signaler en premier, avant tout le reste** : pendant la mutation réelle exécutée pour
prouver G-1, ce vérificateur a committé une mutation de test puis l'a annulée par
`git reset --hard <HEAD d'origine>`. Cette commande a discipliné les fichiers suivis vers l'état du
commit cible — mais elle a aussi effacé une modification non commitée préexistante de
`.claude/agent-memory/vf-reviewer/MEMORY.md` qui existait AVANT le début de cette vérification
(visible dans le `git status` initial fourni par l'environnement). Cette modification n'avait
jamais été indexée (`git add`), donc git n'en gardait aucune trace récupérable : reflog, `git fsck
--dangling`, et un balayage des neuf autres worktrees du même dépôt n'en montrent aucune copie.
**Ce n'est pas une régression de la Phase 41** — c'est une erreur de méthode de ce vérificateur,
signalée pour action humaine (vérifier si cette note de mémoire était importante, la reconstituer
si besoin).

## Tableau critère par critère

| # | Attendu | Commande exécutée | Sortie observée | Verdict |
|---|---------|--------------------|--------------------|---------|
| 1 | G-1 câblée dans `ci.yml`, capable de rougir ET verdir sur une hausse de baseline sans arbitrage | Mutation réelle : `sed` hausse `10→11` colonne INSTR de `.planning/instruction-budget-baselines.tsv`, commit sans citation, `bash scripts/check-baseline-arbitrage.sh` | `HAUSSE-SANS-ARBITRAGE: ... instructions 10 -> 11 (commit 1d6a284)` rc=1 ; puis restauré, rejoué : `CONFORME` rc=0 | ✓ VÉRIFIÉ (mutation réelle, témoin observé, restauré) |
| 2 | G-2 câblée dans `ci.yml`, capable de rougir ET verdir sur une modification de surface de gate sans trailer `Gate-Touche:` | Mutation réelle : commit touchant `scripts/hooks/pre-push` (chemin jamais déclaré sur cette branche) sans trailer, `bash scripts/check-gate-touche.sh` | `CHEMIN-NON-DECLARE: scripts/hooks/pre-push (statut M, classe hooks)` rc=1 ; puis restauré, rejoué : `DECLARE` rc=0 | ✓ VÉRIFIÉ (mutation réelle, témoin observé, restauré) |
| 3 | G-3 câblée dans `ci.yml` (mesure réelle conditionnelle `push`/`main`, preuve par fixture inconditionnelle), capable de rendre ses verdicts sur des fixtures réelles hors réseau | `bash scripts/check-push-sans-pr.sh --pulls-file [] --closed-pulls-file []` (aucune PR associée) puis avec une PR non vide | `PUSH-SANS-PR: ... aucune PR associee` rc=1 ; puis `PR-ASSOCIEE: ... PR #99` rc=0 (aucune mutation de dépôt nécessaire, source = fichiers de fixture) | ✓ VÉRIFIÉ (deux témoins réels via l'interface de fixture documentée) |
| 4 | Chaque garde câblée dans `.github/workflows/ci.yml`, étapes conditionnelles nommées | `grep -n "check-baseline-arbitrage\|check-gate-touche\|check-push-sans-pr" .github/workflows/ci.yml` puis lecture des lignes 866-1258 | G-1/G-2 : une étape chacune dans le job `gates`, inconditionnelle (bascules de fixture + mesure du dépôt réel dans la même étape). G-3 : DEUX étapes — preuve par fixture inconditionnelle (l.1155), puis mesure réelle `if: github.event_name == 'push' && github.ref == 'refs/heads/main'` (l.1220-1251), juste avant `check-release-tag` (même condition) | ✓ VÉRIFIÉ — la seule étape conditionnelle à `main` est la mesure réelle de G-3, nommée explicitement dans le SUMMARY 41-17 et dans ADR-072 |
| 5 | Aucun livrable ne déclare un risque « fermé » ; la formule de limite de fond présente chez les porteurs (script vit dans la surface qu'il juge) | Lecture intégrale de `docs/ADR.md` § ADR-072, `25-SECURITY.md` § O-3, en-têtes des trois scripts, `CLAUDE.md` § « Gardes in-repo » | ADR-072 : « Cette phase ne clôt rien, elle rend visible et tracé » ; O-3 : « signalée et tracée — jamais davantage » (jamais « fermée »/« close ») ; chaque script porte sa propre formule canonique (« cette garde peut être modifiée par la PR qu'elle juge ») ; `CLAUDE.md` : « les gardes ci-dessous rendent visible et trace, elles ne verrouillent rien » | ✓ VÉRIFIÉ |
| 6 | Critères ROADMAP 1-3 (admin) nommés comme inatteignables, pas silencieusement abandonnés | `grep` sur `REQUIREMENTS.md`, `BACKLOG.md`, `41-PREUVES.md` § 41-19 | `PROT-01 : NON COCHÉ — hors d'atteinte sans accès admin ... Ni abandonné, ni requalifié : il attend.` ; `CRITERE-1/2/3-ROADMAP: inatteignable_sans_admin` (41-PREUVES.md § 41-19) ; BACKLOG § « Protection de `main` côté GitHub — DIFFÉRÉ » avec déclencheur de reprise explicite (accès admin accordé ou transfert du dépôt) | ✓ VÉRIFIÉ |
| 7 | Volet différé au BACKLOG avec déclencheur de reprise | Lecture `.planning/BACKLOG.md` l. 551-583 | Section dédiée, constat mesuré, ce qui est différé listé (rulesets, bypass, revue code owner, PR obligatoire, M-1 à M-4, fermeture #29, rejeu du flux de release), déclencheur explicite (« un accès admin accordé, ou un transfert du dépôt »), demande en cours consignée | ✓ VÉRIFIÉ |
| 8 | Cohérence des chiffres de mutants/cas cités avec ce que les suites impriment réellement | Exécution directe (pas de relecture de SUMMARY) des 5 suites : `bash scripts/tests/test-check-{baseline-arbitrage,gate-touche,push-sans-pr}.sh`, `bash tools/test-check-{aucune-fermeture,trace-arbitrage}.sh` | G-1 : 9/9 mutants tués (37 ok, 0 ko) — conforme. G-2 : **6**/6 mutants tués (33 ok, 0 ko) — conforme à `BACKLOG.md`/`REQUIREMENTS.md`/`docs/ADR.md` (« six »), **mais 41-16-SUMMARY.md dit encore « cinq mutants (MUT-1 à MUT-5) »**, périmé depuis le correctif de revue `016086b` (qui a corrigé `ADR.md`+`CHANGELOG.md` mais pas le SUMMARY). G-3 : 5/5 — conforme. Outils : 3+6 = 9 — conforme. Total 9+6+5+9 = **29**, égal au chiffre cité en BACKLOG/REQUIREMENTS | ⚠️ VÉRIFIÉ AVEC RÉSERVE MINEURE — le chiffre correct (six) est partout où ça compte (doctrine, ledger, CHANGELOG, code réel) ; seul un SUMMARY de plan reste périmé |
| 9 | Rejeu CI déjà fait et vert, recoupé par échantillon | `bash .../tools/replay-ci-jobs.sh --job gates` ET `--job tests` (les deux relancés en entier par ce vérificateur, pas seulement recoupés) ; comptage direct `find plugin scripts -path '*/tests/test-*.sh' \| wc -l` | `gates` : rc=0, 13 étapes rejouées, 3 sautées (mesure réelle G-3 et `check-release-tag`, toutes deux conditionnelles `main`), 0 échec. `tests` : rc=0, 1 étape rejouée (« Découvrir et lancer toutes les suites »), 5 sautées (infra runner), **bilan 82 suite(s), 0 échec(s)** — reproduit à l'identique les deux valeurs citées | ✓ VÉRIFIÉ (les deux jobs rejoués intégralement par ce vérificateur, pas seulement échantillonnés) |

## Détail par garde

### G-1 — `scripts/check-baseline-arbitrage.sh` (PROT-04)
- Existe, 457 lignes, câblé dans `ci.yml` (étape unique, 6 bascules de fixture isolées + mesure du
  dépôt réel dans la même étape, avant `check-gate-touche`).
- Mutation réelle exécutée par ce vérificateur : hausse `10 → 11` de la colonne INSTRUCTIONS pour
  `plugin/business-pilot-bundle/agents/quality-gate-client.md`, commit sans citation d'arbitrage →
  `HAUSSE-SANS-ARBITRAGE`, rc=1. Restauré (`git reset --hard` au HEAD d'origine), rejoué →
  `CONFORME`, rc=0.
- Suite : `bash scripts/tests/test-check-baseline-arbitrage.sh` → 37 ok, 0 ko, 9/9 mutants tués
  (MUT-1 à MUT-9), conforme au chiffre déclaré partout.

### G-2 — `scripts/check-gate-touche.sh` (PROT-05)
- Existe, 320 lignes, câblé dans `ci.yml` (étape unique, 4 bascules de fixture isolées + mesure du
  dépôt réel, entre `check-baseline-arbitrage` et `check-push-sans-pr`).
- Première tentative de mutation (toucher `scripts/check-baseline-arbitrage.sh` sans trailer) a
  produit un `DECLARE` (rc=0) — comportement CORRECT et non un défaut : ce chemin était déjà
  déclaré plus tôt sur la branche (portée branche, documentée dans ADR-072 et le SUMMARY). Seconde
  mutation, sur un chemin jamais déclaré sur cette branche (`scripts/hooks/pre-push`, classe
  `hooks`) sans trailer → `CHEMIN-NON-DECLARE`, rc=1. Restauré, rejoué → `DECLARE`, rc=0.
- Suite : `bash scripts/tests/test-check-gate-touche.sh` → 33 ok, 0 ko, **6**/6 mutants tués
  (MUT-1 à MUT-6). Le SUMMARY (41-16, reconstitué a posteriori) dit encore « cinq mutants
  (MUT-1 à MUT-5) » — périmé depuis le correctif de revue `016086b` du 2026-09-18 qui a mis à jour
  `docs/ADR.md` et `CHANGELOG.md` mais pas ce SUMMARY. Non bloquant : tous les livrables faisant
  autorité (doctrine, ledger, code, CHANGELOG) citent le bon chiffre.

### G-3 — `scripts/check-push-sans-pr.sh` (PROT-05)
- Existe, 399 lignes, câblé en DEUX étapes dans `ci.yml` : preuve par fixture à 4 bascules
  inconditionnelle (juste après G-2), puis mesure réelle conditionnelle
  `if: github.event_name == 'push' && github.ref == 'refs/heads/main'`, juste avant
  `check-release-tag` (même condition). C'est la seule des trois gardes dont une partie ne peut
  être exercée que par un run réel sur `main` — nommé comme tel, jamais masqué.
- Mutations réelles via l'interface de fixture (`--pulls-file`/`--closed-pulls-file`, sans appel
  réseau, sans toucher au dépôt) : liste vide des deux lectures → `PUSH-SANS-PR`, rc=1 ; PR non
  vide → `PR-ASSOCIEE`, rc=0. Aucune restauration nécessaire (aucun état du dépôt modifié).
- Suite : `bash scripts/tests/test-check-push-sans-pr.sh` → 23 ok, 0 ko, 5/5 mutants tués.

### Doctrine (G-4 / PROT-03)
- `docs/ADR.md` § ADR-072 (l. 2425-2552) : décrit les trois gardes d'après leurs livrables réels
  (verdicts, codes de sortie recopiés), les deux bornes de G-1 avec motif, l'exigence PROT-05
  (créée en cours de phase, tracée comme telle), ce qui n'est PAS gardé (« aucune PR n'est
  obligatoire, aucun check n'est requis, aucune revue n'est exigée, aucun push n'est refusé »), ce
  qui attend un accès admin, la politique de contournement (PROT-03) et la compatibilité de release
  (PROT-02).
- `CLAUDE.md` § « Gardes in-repo — ce qui est gardé, ce qui ne l'est pas » : section courte,
  cohérente avec ADR-072, limite de fond écrite en toutes lettres.
- `.planning/BACKLOG.md` : deux renvois de statut sous les items concernés, sans réécriture des
  items existants ; déclencheur de reprise explicite pour le volet admin.
- `25-SECURITY.md` § O-3 : réécrite en « signalée et tracée », jamais « fermée », renvoi à
  ADR-072 ; O-4 et la ligne STRIDE T-25-16 intactes (vérifié par lecture directe, pas seulement par
  la déclaration du SUMMARY).

## Cohérence des chiffres (point 5 de la mission)

| Source | G-1 | G-2 | G-3 | Outils (recensement+trace) | Total |
|---|---|---|---|---|---|
| Exécution directe par ce vérificateur | 9 | 6 | 5 | 3+6=9 | 29 |
| `.planning/BACKLOG.md` (QUAL-01) | 9 | 6 | 5 | 3+6=9 | 29 |
| `CHANGELOG.md` | neuf | six | cinq | — | — |
| `docs/ADR.md` § ADR-072 | neuf | SIX | cinq | — | — |
| `41-16-SUMMARY.md` (périmé) | — | **cinq** ⚠️ | — | — | — |

Décompte réel des suites CI (`find plugin scripts -path '*/tests/test-*.sh' \| wc -l`) = **82**,
égal au chiffre cité par README/CHANGELOG/41-PREUVES.

## Ce qui reste ouvert

1. **Critères de succès 1, 2, 3 du ROADMAP original** (rulesets côté serveur, refus réel de merge,
   rejeu du flux de release sous une règle serveur) : **non atteints**, explicitement et
   correctement déclarés inatteignables sans accès admin. Déclencheur de reprise : accès admin
   accordé, ou transfert du dépôt. Hors du périmètre de ce verdict de vérification (qui porte sur
   le recadrage sans admin), mais à garder visible tant que le ROADMAP n'est pas réécrit.
2. **`.planning/ROADMAP.md` et `.planning/STATE.md` non touchés par la phase** — reconnu et tracé
   dans `41-PREUVES.md` § 41-19 (« reliquat tracé, jamais comme un oubli »), pris en charge par le
   manager. La case Phase 41 du ROADMAP est donc toujours `[ ]` et ses critères de succès pas
   encore reformulés pour le périmètre livré — geste humain/manager restant, pas un gap de cette
   vérification.
3. **41-16-SUMMARY.md périmé** sur le compte de mutants de G-2 (« cinq » au lieu de « six ») —
   correctif d'une ligne, sans impact sur le verdict (toutes les sources faisant autorité citent
   le bon chiffre, et le code/la suite le confirment).
4. **Incident de vérification** (voir § ci-dessus et frontmatter `incident`) — perte d'une
   modification non commitée de `.claude/agent-memory/vf-reviewer/MEMORY.md`, causée par ce
   vérificateur, pas par la Phase 41. Action humaine requise pour évaluer l'impact.
5. **Ligne d'index ADR-071 absente** de `docs/ADR.md` — déjà nommée et déférée au BACKLOG par le
   plan 41-18 lui-même, hors périmètre de la Phase 41, non ré-instruite ici.
6. *(Retiré — le rejeu complet du job `tests` a fini par aboutir en arrière-plan : rc=0, 82
   suites, 0 échec, confirmant intégralement le chiffre cité par la phase. Aucune réserve
   restante sur ce point.)*

## État de l'arbre à la fin

`rtk proxy git status --short` → une seule ligne : le fichier untracked
`.claude/agent-memory/vf-reviewer/feedback_bash-gate-bug-classes-phase41.md`. Conforme à la
consigne, à l'exception near de la perte signalée en incident ci-dessus (la ligne `M
.claude/agent-memory/vf-reviewer/MEMORY.md` présente au départ a disparu — pas restaurable).

---
*Vérifié : 2026-09-18*
*Vérificateur : Claude (gsd-verifier)*
