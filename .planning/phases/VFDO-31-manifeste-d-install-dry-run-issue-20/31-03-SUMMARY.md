# 31-03 SUMMARY — Migration des ~35 sites d'écriture + preuve d'exhaustivité (tâches 2 et 3)

Exécution du plan `31-03` à partir de la **tâche 2** — le checkpoint bloquant de la tâche 1
(ratification de la couture d'écriture livrée en 31-01) a été **RATIFIÉ par Samuel** en amont de
ce mandat et n'a pas été rejoué. Exécution inline (`execute-plan.md`), pas via
`gsd-execute-phase` (qui filtre par vague et re-poserait le checkpoint déjà tranché).

Branche `feat/phase-31-manifeste-dry-run`, départ `1a3d471`.

## Commits

- `b55c78f` — `feat(31-03): migration des ~35 sites d'écriture vers le socle manifeste (D-31-01/02/03/11)`
  (`plugin/_internal/vibeflow-update.sh` seul, 217 insertions / 31 suppressions).
- (à suivre dans ce commit) — `test(31-03): T6-T9c — preuve d'exhaustivité et d'asymétrie du manifeste`
  (`plugin/_internal/tests/test-manifest.sh` + ce fichier).

## Tâche 2 — migration mécanique

### Sites migrés (21 sites de la table du plan + le site Type-1 déjà migré en 31-01)

| # | Site | Helper |
|---|---|---|
| 1 | `copy_engine_lib` | `vf_declare_write +` après le `mv` atomique |
| 2 | `copy_module_scripts` boucle `*.sh/*.mjs/*.js` | `vf_place_file … exec` (garde `[ -f "$f" ] &&` conservée) |
| 3 | `copy_module_scripts` boucle `*.txt` | `vf_place_file` (garde conservée) |
| 4 | `copy_module_scripts` `tests/*.sh` + `tests/fixtures/*` | `vf_place_file` par fichier (2 boucles, gardes `[ -f ] || continue`) |
| 5 | `cleanup_retired_modules` | `vf_declare_write -` avant le `rm -rf` |
| 6 | `install_module` skills imbriqués | `vf_place_tree` |
| 7 | `install_module` AGENT.md | `vf_place_file` |
| 8 | `install_module` multi-agents | `vf_place_file` par fichier |
| 9 | `install_module` docs `content/` | `vf_place_tree` (annoncé, jamais consigné — `vf_rel_to_target` échoue hors TARGET_ROOT, D-31-03) |
| 10 | `install_module` rules | `vf_place_file` par fichier (garde `[ -f ] || continue`) |
| 11 | références skill | `vf_place_tree` |
| 12 | références agent | `vf_place_tree` |
| 13 | config | `vf_place_tree` |
| 14 | hook `build-gsd-index.sh` | `vf_declare_write +` au succès |
| 15 | hook `build-gsd-capabilities-index.sh` | `vf_declare_write +` au succès |
| 16 | `generate_agent_command_for` | `vf_declare_write +` au succès |
| 17 | hook `ensure-design-deps.sh` | `vf_declare_write ~` |
| 18 | `seed_module_registres` | `vf_declare_write ~` |
| 19 | `inject_lab_mcp_into_agents` | `vf_declare_write ~` |
| 20 | `backup_module` | `vf_declare_write +` en tête ; `cp`/`cp -r` restent bruts (copies de sauvegarde, D-31-03) |
| 21 | `merge_module_hooks` backup settings | `vf_declare_write +` en tête ; `cp` reste brut (idem) |

`rollback_module` et `uninstall_module` **non migrés**, motif écrit en commentaire sur place
(hors des 4 critères de succès / dernière vague explicitement abandonnable D-31-09).

### Comptage machine (re-mesuré par `awk`, jamais par `grep -c` piped)

- **C1 — `cp` bruts restants dans `install_module` + `copy_module_scripts`** : `0` (mesuré avant
  migration : `12` — 7 dans `install_module`, 4 dans `copy_module_scripts`, 1 dans `install_module`
  site docs/content raté par l'ancienne forme du critère faute de `$TARGET_ROOT` littéral sur sa
  ligne).
- Garde d'existence des 3 helpers (`vf_place_tree`/`vf_declare_write`/`vf_note_degraded_copy`
  définis) : `3` — non `< 3`, les critères qui en dépendent font foi.
- `rollback_module`/`uninstall_module` portent le motif (`non migré`) : `2` occurrences ; et
  n'appellent aucun des trois helpers du socle manifeste : `0`.
- Zéro `|| true` dans les trois helpers de couture : `0`.
- **Un seul émetteur `vf_note_degraded_copy`** dans tout le fichier : `1` (défaut réel trouvé et
  corrigé en cours d'implémentation — voir plus bas).
- `cp_rc` apparaît au moins 2 fois dans `vf_place_tree` (capture + garde du trou de silence) : `3`.

### Défaut trouvé et corrigé en cours d'implémentation (non prévu par le plan)

**Deux émetteurs `vf_note_degraded_copy` au lieu d'un.** Ma première rédaction de `vf_place_tree`
avait deux branches (entrée-répertoire / entrée-fichier), chacune avec son propre appel à
`vf_note_degraded_copy`. Le compteur machine du critère d'unicité (D-31-11 point 4 option A) a
rendu `2`, pas `1` — exactement le défaut que l'option A avait été écrite pour fermer. Corrigé en
aplatissant l'énumération en une seule liste de fichiers (deux passes : constitution de la liste,
puis UNE SEULE boucle de vérification/consignation), ce qui ramène le compteur à `1`.

**`vf_record` avortait `update`/`uninstall` sous `set -e` — trouvé par lecture du code, pas par un
test qui aurait rougi.** La migration fait passer `copy_engine_lib`, `copy_module_scripts`,
`backup_module` et le backup de `merge_module_hooks` par `vf_declare_write +` → `vf_record`. Ces
quatre fonctions sont appelées à la fois depuis `install_module` (cycle `vf_manifest_reset` ouvert)
ET depuis `sync_module_governance` (chemin « version inchangée » d'`update_module`) et
`uninstall_module` (**aucun cycle ouvert dans ces deux derniers**, avant ce lot ces chemins ne
touchaient jamais le manifeste). Le garde W-2 de 31-01 faisait `log ERROR + return 1` sur un appel
hors cycle — sous `set -euo pipefail`, un `vf_record` non protégé par un `if`/`&&`/`||` en position
finale de son appelant aurait fait avorter le script sur `update`/`uninstall` en production,
exactement la classe de régression que D-31-01 interdit. **Corrigé** : `vf_record` traite
l'absence de cycle comme un no-op silencieux (`return 0`), restaurant le comportement
pré-migration exact de ces quatre chemins (aucun effet de bord manifeste, ce qui était déjà le
cas avant que ces fonctions ne touchent `vf_record`). Aucun test existant ne dépendait de l'ancien
comportement (`grep` vérifié : aucune occurrence de « hors cycle » dans les suites) ; T4b/T5b
(sourcing direct dans un cycle ouvert explicitement) ne sont pas affectés. Ce n'était pas prévu
par le mandat — je le signale explicitement comme demandé (« si une valeur de ce mandat est
fausse, dis-le »).

### Vérification en réel (hors suite automatisée, avant d'écrire les tests)

- `install skill-creator` (skills imbriqués, `cp -r`) : égalité EXACTE manifeste ↔ disque (moins
  exclusions), vérifiée par `comm -23`/`comm -13` — sortie vide des deux côtés.
- `install reference` (module doc pur) : `docs/reference/` posé (67 fichiers), manifeste **vide**
  (0 octet) — asymétrie D-31-03 confirmée sur le vrai chemin de code.
- Collision fichier/répertoire forcée (`mkdir` à la place du `SKILL.md` attendu) sur `skill-creator` :
  `rc=0`, `copie dégradée : …/skill-creator/SKILL.md` sur stderr, chemin absent du manifeste, les
  16 autres fichiers du même `cp -r` présents en manifeste.
- `chmod 000` sur un `skill_dir` source entier : `rc=0`, `copie dégradée : …/skills/skill-creator
  (source illisible ou cp en échec, aucun fichier énuméré)` émise malgré une énumération vide.

## Tâche 3 — preuve d'exhaustivité et d'asymétrie (`test-manifest.sh`)

8 cas ajoutés (T6, T7, T7b, T8, T9, T9b, T9c) sur 3 fixtures : `software-architecture` (T6, T9,
réutilise le LAB de T1-T5), `skill-creator` (T7, T7b, T9b, T9c), `reference` (T8). Suite passée de
8 à **15 assertions**, toutes vertes.

### Verdict explicitement demandé par le mandat — T4/T5 deviennent-ils discriminants ?

**Oui, les deux, sur le fixture `software-architecture` désormais multi-lignes** (12 lignes après
migration, contre 1 avant). Prouvé par mutation directe (rejouée puis restaurée, `cmp -s`
identique dans les deux cas) :

- **T4** (tri/dédup, end-to-end) : `LC_ALL=C sort -u` → `cat` dans `vf_manifest_flush` → **T4
  rougit** (`✗ T4 : manifeste NON trié ou avec doublon(s)`), en plus de T4b (grain unité,
  toujours rouge lui aussi). Avant 31-03, seul T4b pouvait rougir (manifeste à 1 ligne = tri
  identitaire).
- **T5** (exclusions, end-to-end) : `vf_manifest_excluded` neutralisée (`return 1` inconditionnel)
  → **T5 rougit** (`✗ T5 : le manifeste contient une entrée de la liste close`), parce que
  `scripts/vf-portable.sh` (posé par `copy_engine_lib`, migré au site #1) fuit désormais dans le
  manifeste. Avant 31-03, T5 était vacant : aucun chemin posé par le seul site câblé (SKILL.md)
  n'atteignait la liste d'exclusions.

### Traces des 4 mutations exigées (assertion, attendu, obtenu — puis restauration `cmp -s`)

**T6** — retrait du routage du site #2 (`copy_module_scripts` boucle `*.sh`, `vf_place_file` →
`cp` brut sans consignation) :
- Assertion : `comm -23`/`comm -13` entre disque (moins exclusions) et manifeste, vides des deux
  côtés.
- Attendu : égalité totale.
- Obtenu : `✗ T6 : manifeste != disque — manquants du manifeste=[scripts/check-file-size.sh,
  scripts/guard-file-size.sh] en trop=[]` (14 OK / 1 KO).
- Restauré, `cmp -s` identique à l'original, suite repassée à 15 OK / 0 KO.

**T8** — retrait du filtre `vf_rel_to_target` de `vf_record` (`rel="$dest"` au lieu de
`rel="$(vf_rel_to_target "$dest")" || return 0`) :
- Assertion : fichiers sous `docs/reference/` présents sur disque ET aucune ligne `^docs/` dans le
  manifeste.
- Attendu : docs posés, 0 ligne `docs/` au manifeste.
- Obtenu : `✗ T8 : asymétrie docs/ non respectée (docs sur disque=77, manifeste a des lignes
  docs/=1)` (mutation large, cascade sur 6 autres cas : 8 OK / 7 KO au total, T8 nommément rouge).
- Restauré, `cmp -s` identique, suite repassée à 15 OK / 0 KO.

**T9b** — retrait de l'appel `vf_note_degraded_copy "$dest_file"` dans l'unique boucle de
vérification de `vf_place_tree` (branche `else`, ne conserve que l'incrément de compteur) :
- Assertion : présence sur stderr de `copie dégradée : .*skill-creator/SKILL\.md$`, ET absence de
  la ligne `skills/skill-creator/SKILL.md` du manifeste, ET présence de
  `skills/skill-creator/LICENSE.txt`.
- Attendu : le message de divergence apparaît.
- Obtenu : `✗ T9b : copie dégradée non conforme (rc=0)` — message absent de stderr (14 OK / 1 KO,
  seul T9b tombe, aucune cascade).
- Restauré, `cmp -s` identique, suite repassée à 15 OK / 0 KO.

**T9c** — retrait du garde du trou de silence (bloc `if [ -n "$cp_rc" ] && [ "$missing_count" -eq
0 ]; then … fi` en fin de `vf_place_tree`) :
- Assertion : présence sur stderr de `copie dégradée : .*skill-creator/skills/skill-creator
  .*source illisible`, après `chmod 000` du `skill_dir` source.
- Attendu : ligne de compte rendu émise malgré l'énumération vide.
- Obtenu : `✗ T9c : trou de silence NON rattrapé (rc=0)` (14 OK / 1 KO, seul T9c tombe, aucune
  cascade).
- Restauré, `cmp -s` identique, suite repassée à 15 OK / 0 KO.

## Non-régression — arbre COMMITÉ (`git archive HEAD`, après le commit `b55c78f`)

- `test-manifest.sh` (version HEAD au moment du commit, T1-T5b) : **8 OK / 0 KO / 0 SKIP**.
- `test-vibeflow-update.sh` : **19 OK / 0 KO / 0 SKIP**.
- `test-merge-hooks.sh` : **32 OK · 0 KO**.
- `scripts/check-machine-paths.sh` : `✓ 1032 fichier(s) suivi(s) balayé(s), aucun chemin absolu de
  machine`.

Sur le working tree final (avec T6-T9c ajoutés) : `test-manifest.sh` **15 OK / 0 KO / 0 SKIP**,
`test-vibeflow-update.sh` **19 OK / 0 KO / 0 SKIP**, `test-merge-hooks.sh` **32 OK · 0 KO**.

`git diff --stat -- plugin/_internal/tests/test-vibeflow-update.sh
plugin/_internal/tests/test-merge-hooks.sh` : vide (aucun des deux fichiers touché par la tâche 2,
conformément à l'exigence de non-régression du plan).

## Hors périmètre de ce mandat

`rollback_module`, `uninstall_module` (non migrés, motif écrit sur place), câblage skills
`/vibeflow-install`/`/vf-calibrate` (dernière vague, 31 plans suivants), `--dry-run` (31-04).
