---
phase: 67-cockpit-floorplan-socle-partage
plan: 06
status: complete
requirements: [CKPT-10]
commits: [7f5f5421, ebc63e98]
actuals:
  tasks: 3
---

# 67-06 SUMMARY — module `cockpit`, verbe `/vf-cockpit`, pose par l'engine

Exécution inline. Les tâches 1 et 2 (tracer + trois scopes) partagent la suite d'installation : un seul commit (7f5f5421) ; la tâche 3 (documentation, manuel, gates) a le sien (ebc63e98, trailer `Ajout-Retrait`). Aucune VERSION racine, aucune release.

## Livré
`plugin/cockpit/{module.json, VERSION, CHANGELOG.md, README.md}` (module sans clé `roles`, `requires` vide), skill de classe `user` `skills/vf-cockpit/SKILL.md` + `agents/openai.yaml`, lanceur `scripts/vf-cockpit.mjs` (open, build, stop, status ; codes 0, 2, 3, 4, 5), suite `plugin/_internal/tests/test-vibeflow-update-cockpit.sh` (I1-I8, 178 lignes), compteurs des README racine (19 modules, 135 puis 136 suites), manuel EN/FR (catalogue + 24 skills).

## Preuves
- `test-vibeflow-update-cockpit.sh` : `== resultat : 11 ok, 0 ko ==`. I4 : 18 comparaisons `cmp` de binaires (4 `.woff2` + 2 `.png`, trois scopes) ; I4b : 216 fichiers texte à l'octet (arbre du moteur, scripts, skill) ; I5 : empreintes `cksum` identiques à la seconde pose, `.gitignore` local sans doublon ; I7 : vrai `~/.claude` inchangé (956 fichiers).
- **Fichiers texte réécrits sous `--target` (I8)** : `scripts/vf-cockpit-code-vf.mjs`, `scripts/vf-cockpit-who.mjs`, `skills/vf-cockpit/SKILL.md` (65 comparés ; seule la réécriture de `.claude/` a eu lieu) ; le lanceur posé sous la cible assemble, le rendu compte 0 occurrence du nom amont.
- `BOOTSTRAP` de `check-instruction-budget.sh` : code 0, `2610 tokens … ligne 2610` **avant et après** (le plan n'ajoute rien à la clé `@bootstrap:socle`).
- `check-skills.sh --strict --skills-dir=plugin --callers-root=plugin` rc 0 (24 SKILL.md à l'arbre). Témoin : même commande sur un dossier jetable contenant le skill SANS `agents/openai.yaml` → rc 1, « user-invoked niche sans agents/openai.yaml … P414-D-03 » ; avec le fichier → rc 0.
- `check-overlaps.sh --strict` sur un lab posé → rc 0 : `✓ aucun recouvrement connu présent des deux côtés — rien à signaler`.
- Les trois `check-agents` (blocs `run:` de ci.yml, extraits tels quels) : 7 dossiers, 7 AGENT.md, 7 en monde fermé, 0 échec. `check-version-sync` ✓, `check-machine-paths` ✓, `check-gate-touche` DECLARE, `check-ajout-retrait --strict` rc 1 nommant le SKILL.md neuf tant que le trailer manque (témoin), puis rc 0.

## Mutants (sortie rouge)
### engine qui altère les `.woff2` à la pose (copie jetable de `vibeflow-update.sh`, `VF_COCKPIT_TEST_ENGINE`)
```
  ✗ I4 : binaire altéré à la pose (… : ./assets/vendor/fonts/inter-latin-ext-wght-normal.woff2)  (×12 : 4 fichiers × 3 scopes)
```
### engine qui réécrit aussi les `.png` sous `--target` (mutant du plan : `*.png` ajouté à `vf_target_rewrite_ext`)
Resté **vert** tel quel : la réécriture ne trouve aucun `.claude/` dans un PNG, et `sed` BSD refuse les octets invalides en locale UTF-8. Le mutant n'est discriminant que s'il modifie réellement les octets (règle `s#PNG#png#g` ajoutée à la chaîne `sed`) et sous `LC_ALL=C` :
```
  ✗ I8 : binaire altéré sous --target : …/skills/cockpit-moteur/./assets/favicon.png
  ✗ I8 : binaire altéré sous --target : …/skills/cockpit-moteur/./assets/logo.png
  == resultat : 10 ok, 2 ko ==
```
(I4 ne joue pas sous `--target` : c'est I8 qui garde les binaires dans ce cas, contrairement à ce que dit le plan.)

## Écarts au plan
- Tâches 1 et 2 dans un seul commit (suite écrite d'un trait).
- I1 vérifie aussi la réutilisation d'un serveur vivant (second `open` imprime la même adresse) et l'absence de dossier amont et de `CLAUDE.local.md` dans le lab.
- I5 : l'engine ignore le **dossier** du skill (`.claude/skills/vf-cockpit/`), pas `SKILL.md` ; la suite compte cette ligne.

## Finding (hors périmètre, engine)
En scope `local`, l'engine n'ajoute pas au `.gitignore` les fichiers de données de `scripts/*.json` (`vf-cockpit-interface.json`) ni `scripts/tests/*.sh` ni ses marqueurs `.vibeflow-*` : ils restent visibles comme non suivis. Comportement général de `gitignore_add_paths`, pas propre au cockpit ; T-67-34 est tenu pour les chemins que la suite garde (skill, arbre du moteur, scripts `.mjs`).

STATE.md identique à la baseline.
