# Mission — Phase 30 « Portabilité Windows II »

**Manager** : `vf-dev-manager` · **Dates** : 2026-08-15 → 2026-08-16
**Branche** : `feat/phase-30-portabilite-windows-ii` (poussée) · **Milestone** : fiabilite-v1.0
**CI finale** : run `31919876646` — **4 jobs sur 4 verts**

---

## 1. Plan de bataille

DAG de 17 nœuds (`.planning/MISSION-30.dag.json`), 4 vagues, périmètres de fichiers déclarés
nœud par nœud pour autoriser le dispatch parallèle. Verrou de driver pris au démarrage, battu
entre chaque étape, relâché à la clôture. Gate d'invariants : **SAIN** (exit 3). Les trois flags
d'enchaînement étaient déjà à `false`.

Écart au plan initial : **2 nœuds ajoutés en cours de mission**.

- `exec-30-09` — filet `SessionStart` de détection des chemins d'interpréteur périmés, né de
  l'addendum humain du 2026-08-15.
- `solde-30` — solde des findings de revue et des reliquats.

---

## 2. Décisions humaines et arbitrages

| Décision | Qui | Effet |
|---|---|---|
| **D-01, option A** | Samuel, 2026-08-15 | Chemin absolu de bash écrit à l'install, **routage borné** vers `settings.local.json` ; amendement du critère LOCK-02 de la Phase 32 |
| Trou `.gitignore` scope `local` | Samuel | Corrigé **dans** la phase |
| Post RFC upstream (D-09) | Samuel, 2026-08-15 | Approuvé — issue `open-gsd/gsd-core#3556` déposée |
| Push + constat CI | Samuel, 2026-08-16 | Accordé ; **PR et release racine restent hors mission** |
| Travail tiers — **option B2** | Samuel, 2026-08-16 | Contenu cockpit isolé sur `spike/cockpit-live` |

**Arbitrage rendu par le manager** : le compteur « N suites » des deux README (55 → 61) est remis
d'aplomb **dans la phase**, contre le précédent du 2026-07-28 qui le fait voyager avec le commit de
release. Motif : la phase a elle-même **créé** la dérive en ajoutant des suites, et le geste ne
touche ni `VERSION` racine, ni `plugin.json`, ni `marketplace.json`.

---

## 3. Livré

**Exigences** : PORT-01, PORT-02, PORT-03, PORT-04, PORT-05, LEDG-03, WKTR-03 — plus les
11 décisions D-01..D-11 et les 4 items de l'addendum humain.

- `merge-hooks.sh` lit la forme **exec** (`args`), résout le chemin absolu de bash, **route de
  façon bornée** vers une seconde cible, dédup **cross-cible**, `remove` sur les deux cibles.
- Lib partagée `plugin/_internal/lib/vf-portable.sh` conforme au contrat de la PR #29 (5 symboles,
  bloc localisateur **identique octet pour octet** sur 4 consommateurs, vérifié en `cmp`).
- Codes de sortie normalisés sur **tout le parc** (12 scripts), conditionnés au drapeau de mode
  hook — sans le drapeau, aucun code ne change.
- Les 5 entrées de hook du périmètre dev en forme exec ; **26 entrées** inventoriées et classées
  advisory/bloquante, dont **5 bloquantes**.
- Filet `check-hook-paths.sh` — invoqué en `bash` **nu** (paradoxe d'amorçage assumé, gravé en ADR).
- ADR-071 (forme exec, second temps après ADR-054) + amendement daté du critère LOCK-02.
- RFC upstream `open-gsd/gsd-core#3556` déposée, traçabilité D-11 en double (REQUIREMENTS + STATE).
- Veille de release gsd-core > 1.10.0 — seul déclencheur tracé de la Phase 35.

**Chiffres** : 52 commits de phase · **61 suites, 0 échec** · `check-version-sync`,
`check-machine-paths`, `check-state-integrity`, `check-agents --strict` verts.

---

## 4. Ce que la mission a appris

### Cinq faux verts du même motif
Un rapport affirmant une couverture que le disque ne portait pas. À chaque fois trouvé par un
**juge externe**, jamais par l'auteur, jamais par la suite de tests.

1. `passed` / `findings: []` avec **deux éléments de mandat absents** (routage, amendement LOCK-02).
2. Rapport vert masquant **3 suites CI rouges** jamais exécutées.
3. Matrice annoncée « générique, 8 séquences » dont **6 restaient vertes sur du code cassé**.
4. Assertions `m2` **vraies indépendamment de la mutation** — elles ne testaient rien.
5. `EXPECT_TOTAL = 6` validé à la main contre un univers que la CI ne construit jamais.

**Le contrôle qui manquait à chaque fois, désormais exigible** : vérifier qu'un cas **passe au vert
sur le code NON muté** *et* **rougit sur le code muté**. Un rouge sans trace (assertion, attendu,
obtenu) ne compte pas.

### Le local vert ne prouve rien sur la cible
61 suites vertes en local, CI rouge au premier push : la preuve PORT-05 comptait un univers
(deux modules installés à la main) que le job ne construit pas (fermeture de dépendances résolue,
sans `software-architecture`). Corrigé en **dérivant** l'attendu de la fermeture réellement
installée. C'est la leçon #38 rejouée — et l'étape l'a attrapée sur elle-même.

### Le verrou de driver reste déclaratif
Une session tierce a commité **8 fois** sur la branche pendant la mission, verrou tenu et non
périmé. Contenu préservé verbatim, jamais écrasé, puis isolé sur `spike/cockpit-live` par
chirurgie d'historique — preuve : **679 suppressions / 0 insertion**, amendement LOCK-02 et
traçabilité D-11 intacts, `BACKLOG.md` restauré à l'octet près de son état de base.

### Erreur de mandat du manager, corrigée
Le protocole de commit interdisait `git add` **tout court** — mécaniquement impossible pour un
fichier neuf. Un worker s'est bloqué, un autre a dû dévier (et l'a signalé, correctement). La règle
est **asymétrique** : `git add` avec pathspec explicite est sans danger ; c'est le `git commit`
**nu** qui balaie l'index partagé. Mémoire corrigée en conséquence.

---

## 5. Reliquats

| Reliquat | Où | Statut |
|---|---|---|
| Hook doctor conductor (D-05) | `30-RELIQUATS.md` | Différé, tracé |
| `test-dev-orchestrator.sh` hors contrat §7 | `30-RELIQUATS.md` | Signalé à l'amont |
| 4 mineurs de revue (séparateur `\t`, branches défensives, `mk_settings()`, `--help` verbeux) | `30-RELIQUATS.md` | Jugés faible risque, non corrigés |
| Substitution `{{VF_BASH}}` indépendante de la destination | commentaire dans `merge-hooks.sh` | Inatteignable avec le contrat d'appel actuel |
| Commit doc `#3302` | branche Phase 30 | **Déviation déclarée** — comment-only, vérifié juste, renforce le gate Phase 35 |

---

## 6. Next step

**Ouvrir la PR de la Phase 30** — c'est le seul geste qui manque, et il est **gaté humain** : le
feu vert du 2026-08-16 couvrait le push et le constat CI, pas la PR ni le merge. La branche est
poussée, la CI verte sur les 4 jobs, la phase vérifiée.

La **release racine** (`VERSION` / `plugin.json` / `marketplace.json` + tag + release GitHub) reste
hors périmètre de phase, comme convenu. **7 modules ont été bumpés** et attendent distribution.
