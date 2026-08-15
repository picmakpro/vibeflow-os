# 26-15 — Comblement : dégraissage réel des README (build-26 / degraissage)

## Contexte

Le nœud `degraissage` du DAG Phase 26 (`.planning/missions/dag-phase26.json`) avait bien traité
`INSTALL.md` (192 → 22 lignes) mais laissé les deux README **grossir** au lieu de maigrir
(README.md 295 → 297, README.fr.md 301 → 303). Ce comblement reprend le mandat sur les deux
README + un lien mort pré-existant dans `plugin/consolidator/README.md`, sur la branche déjà
active `feat/phase-26-manuel-utilisateur`.

Fondement : `manual/fr/README.md:12-14` fixe la frontière — le README raconte le projet,
`docs/` porte la mémoire de travail des agents, et **le manuel porte l'usage**. Les six sections
usage/explication du README (cycle dev, missions longues, au-delà du dev, mémoire, architecture,
modules) sont couvertes par le manuel (44 pages, `manual/toc.yml`) et ont donc pu être réduites
à une accroche + un renvoi, sans perte d'information.

## Avant / après, section par section

| Section `##` | Avant (EN) | Après (EN) | Avant (FR) | Après (FR) | Sort |
|---|---|---|---|---|---|
| Header/pitch/badges/nav | 27 | 27 | 27 | 27 | **intact** |
| Le problème | 11 | ~12 | 11 | ~12 | **intact** (raccourci non nécessaire) |
| 🔁 Le cycle dev | 23 | 9 | 23 | 9 | **compressé** → `04-development-cycle/the-cycle-at-a-glance.md` |
| 🤖 Missions longues | 32 | 9 | 32 | 9 | **compressé** → `05-agent-team/a-long-mission.md` |
| 🧪 Au-delà du dev | 31 | 9 | 31 | 9 | **compressé** → `02-concepts/what-is-a-lab.md` |
| 🧠 La mémoire qui tient | 12 | 9 | 12 | 9 | **compressé** → `07-under-the-hood/anatomy-of-an-installed-lab.md` |
| 🏗 Architecture | 27 | 10 | 27 | 10 | **compressé** → `07-under-the-hood/the-machine-gates.md` |
| 🚀 Install(ation) | 13 | 14 | 13 | 14 | **intact** |
| 📦 Modules | 44 | 12 | 44 | 12 | **compressé** (table des 17 modules retirée) → `03-modules/catalog.md` + commandes/skills/agents |
| 🔒 Confiance | 13 | 14 | 13 | 14 | **intact** |
| 🧭 Versioning | 31 | 33 | 31 | 33 | **intact, historique des 8 entrées mot pour mot identique** |
| 👤 Auteurs | 4 | 4 | 4 | 4 | **intact** |
| 📄 Licence | 5 | 5 | 5 | 5 | **intact** |
| **Total** | **297** | **180** | **303** | **185** | |

`wc -l README.md README.fr.md` → **180 README.md, 185 README.fr.md** (fourchette cible
120-160 dépassée de peu côté cible « ambitieuse », mais dans la fourchette de gate 120-200 —
le tableau de versioning intact (8 entrées longues, non compressibles par mandat explicite)
pèse à lui seul ~33 lignes des deux côtés).

Parité stricte vérifiée : **12 sections `##` de chaque côté, même ordre** (cf. sortie
`grep -n "^## "` sur les deux fichiers — identique à une ligne près par construction).

## Balayage des ancres et liens

1. **Ancres internes du dépôt vers `README.md#…` / `README.fr.md#…`** : `grep -rn` sur
   `CLAUDE.md`, `docs/`, `plugin/**/*.md`, `.github/`, `manual/**`, et l'autre README — **zéro
   occurrence** en dehors de `manual/**` lui-même, où toutes les mentions `README.md` renvoient
   à l'index de langue du manuel (`manual/fr/README.md` ou `manual/en/README.md`), jamais au
   README racine. Confirmé fichier par fichier (81 occurrences dans `manual/fr/**` et
   `manual/en/**`, toutes de la forme `[↑ Sommaire](../README.md)` / `[↑ Contents](../README.md)`).
2. **Nav interne du README** (ligne 18, liens `#-the-dev-cycle--…` etc.) : **non touchée par le
   diff** (`git diff HEAD~1 HEAD` confirme zéro changement sur cette ligne) — les en-têtes `##`
   ciblés n'ont pas changé de libellé, seul leur contenu a été compressé, donc les ancres restent
   valides.
3. **17 liens relatifs neufs/modifiés** (`./manual/en/...`, `./manual/fr/...`,
   `../../INSTALL.md`) : résolution vérifiée par script Python (`os.path.exists` sur le chemin
   normalisé depuis le dossier du fichier source) — **aucun lien mort**.
4. **`bash manual/.tools/check-manual.sh`** → exit 0, les 6 contrôles C0-C6 passent (le manuel
   lui-même n'a pas été touché, ce contrôle garantit qu'aucune régression n'a été introduite par
   la présente mission).

## Correction du lien mort (Tâche 2)

`plugin/consolidator/README.md:32` — `../INSTALL.md` (résolvait vers `plugin/INSTALL.md`,
inexistant) → `../../INSTALL.md` (résout vers le vrai `INSTALL.md` racine, celui-là même
retravaillé par le mandat de dégraissage précédent). Seule cette ligne a été touchée dans
`plugin/`.

## Intouchés (vérifié)

Badges, triade de release (`VERSION`, `plugin/.claude-plugin/plugin.json`,
`.claude-plugin/marketplace.json`), historique des versions (8 entrées mot pour mot),
`CHANGELOG.md`, `.gitignore`, `.github/**`, `scripts/**`, `docs/**`, `.planning/ROADMAP.md`,
`.planning/STATE.md`, `manual/**`, `INSTALL.md` (déjà traité), `plugin/skill-creator/**` —
`git diff --stat` confirme 3 fichiers modifiés seulement (`README.md`, `README.fr.md`,
`plugin/consolidator/README.md`).

## Commits

- `4b450bd` — "Comblement — dégraissage réel des README vers le manuel (Phase 26)" (3 fichiers :
  `README.md`, `README.fr.md`, `plugin/consolidator/README.md`).
- `b0a281b` — "Comblement — retire un artefact `</content>` en fin des deux README" (correctif de
  revue, 2 fichiers).

Les deux sur `feat/phase-26-manuel-utilisateur`.

## Revue (`vf-reviewer`, tour 1)

Verdict : `gaps_found`.

- **Bloquant, auto-fixé** — les deux README se terminaient par une ligne littérale `</content>`
  (artefact d'outillage, aucun sens Markdown), visible sur la page GitHub publique du repo juste
  après la licence. Confirmé par lecture directe des fichiers (`README.md:180`,
  `README.fr.md:185`), corrigé au commit `b0a281b`. Après correctif : `README.md` = 179 lignes,
  `README.fr.md` = 184 lignes (toujours dans la fourchette de gate 120-200).
- **Majeur, hors périmètre — remonté au manager, PAS corrigé** : le diff de dégraissage a supprimé
  deux blocs que **6 pages du manuel citent nommément comme source vivante et datée**, publiées au
  commit `28ccf34` (avant ce comblement) :
  - Le tableau « Efficiency, quantified » / « L'efficience, chiffrée » (ex-section 🤖 Missions
    longues) est reproduit et daté du « 2026-08-01 » dans
    `manual/en/06-reference/cost-and-models.md:80-96` et
    `manual/fr/06-reference/couts-et-modeles.md:83-99`, avec la phrase : *« Si tu veux vérifier ce
    chiffrage toi-même, `README.md` (racine du dépôt), section "Efficiency, quantified," est la
    source »* — section qui n'existe plus après compression.
  - Le tableau « Les 17 modules en détail » (ex-section 📦 Modules) est cité comme preuve d'une
    confusion présente « au README racine » entre skills et commandes (`/vf-design`,
    `/vf-sketch`) dans `manual/en/06-reference/commands.md:90-91`,
    `manual/fr/06-reference/commandes.md:91-92`, `manual/en/06-reference/skills.md:107-109` et
    `manual/fr/06-reference/skills.md:110-112` — le tableau qui portait cette confusion a été
    entièrement retiré, l'affirmation ne pointe plus vers rien.

  **Non corrigé** : la correction demanderait soit de rouvrir `manual/**` (explicitement
  **INTERDIT en écriture** dans le périmètre de ce mandat), soit de réintroduire dans le README le
  contenu que le même mandat demande de retirer — deux options qui se contredisent et qui
  dépassent ma délégation. Remonté au manager comme point d'arbitrage (`ask-user`) : quelle page
  gagne (README compressé vs exactitude datée du manuel), et qui porte l'édition de `manual/**`.

Tous les autres axes de revue sont en **PASS** : les 17 liens du diff résolvent, parité stricte
(12 sections `##`, même ordre), blocs figés (Installation, Confiance, Versioning à 8 entrées,
Auteurs, Licence, badges) sans aucun diff, correctif du lien mort isolé et correct, cohérence
linguistique FR/EN des passages ajoutés, contenu compressé substituable par les 6 pages du manuel
liées pour les sections elles-mêmes (le vrai trou est la citation datée, pas le pointeur direct).
