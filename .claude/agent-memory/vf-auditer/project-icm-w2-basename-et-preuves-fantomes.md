---
name: project-icm-w2-basename-et-preuves-fantomes
description: Phase 29 vague 2 (check-map-drift.sh, scaffold-docs.sh) — cycle correctif/re-audit sur basename, comparaison P2, preuves de test décoratives
metadata:
  type: project
---

Audit du nœud `audit-w2` (Phase 29, ICM gains) sur `plugin/conductor/scripts/check-map-drift.sh`
(neuf) et `scaffold-docs.sh` a traversé DEUX passages, tous deux vérifiés par exécution (jamais
seulement lecture) :

**Passage 1 (findings originaux)** :
1. `basename "$f"` cassait sur une entrée `git ls-files` à tiret initial TOP-LEVEL (répertoire
   racine, pas sous-dossier) — fail-safe mais stderr pollué.
2. T-29-02-02/T-29-04-02 revendiquaient des cas de suite (espace, tiret initial) absents du code
   livré.

**Passage 2 (re-audit du correctif, commits b0346ed..413f0d9)** — verdict global : gaps_found.
- Les 3 `basename` ont été remplacés par `${f##*/}`/supprimés — **fix réel et vérifié** : un
  fichier top-level `-orphelin-tiret.md` (racine, sans `/`) casse `basename` sur le code d'AVANT
  (« illegal option -- o » ×3 en stderr) et passe proprement sur le code d'APRÈS. `${f##*/}` est
  sûr ici car `$f` vient exclusivement de `git ls-files`, qui ne rend jamais de chemin à `/` final
  (pas de risque de la variante "chaîne vide" de `${f##*/}` vs `basename` sur ce site d'appel).
- **MAIS** : le cas de suite ajouté pour « prouver » ce fix (« Robustesse — nom de fichier à tiret
  initial ») place le fichier sous `refs/-orphelin-tiret.md` (SOUS-DOSSIER) au lieu de la racine —
  l'argument passé à `basename` ne commence alors jamais par `-` (il commence par `r` de `refs/`),
  donc CE FIXTURE NE REPRODUIT PAS le crash sur le code d'avant (vérifié : old.sh et new.sh
  produisent une sortie strictement identique sur ce fixture, aucun stderr). Le commentaire du
  test affirme pourtant explicitement « avant correctif, les 3 sites basename cassaient » — c'est
  FAUX pour ce fixture précis. Récidive du même anti-pattern « preuve fantôme » que le passage 1,
  DANS LE MÊME CYCLE censé le corriger. Le code de prod est bon ; la preuve ne l'est pas.
- P2 sens B : comparaison réécrite en chemin résolu complet (plus de match par suffixe de
  basename) — fix réel, vérifié par fixture `refs/orphan.md` (top-level, non cité) vs
  `refs/sub/orphan.md` (cité) : rc=3 (bug, faux négatif) sur l'ancien code, rc=0 (correct) sur le
  nouveau. Rewrite fait de la comparaison de STRING pure (aucun test `-e` sur le chemin construit)
  → aucune traversée introduite par ce correctif spécifique.
- P1 sens A : token `@/chemin/absolu` désormais ignoré (`case "$tok" in /*) continue;; esac`) —
  fix réel pour un faux positif vérifié (chemin absolu réel hors repo, existant sur disque,
  auparavant signalé à tort comme divergence). Trade-off assumé et documenté : angle mort total
  sur les tokens absolus (jamais vérifiés), cohérent avec ADR-031 cité dans le commentaire du fix.
- scaffold-docs.sh : validation `--index` déplacée avant toute écriture (l.71-74, avant les
  `write_stub()` transverses l.100+) — fix réel, vérifié : sur dossier `--index` absent, l'ancien
  code laissait `docs/_transverse/` orphelin (échec non atomique), le nouveau ne laisse rien.
- **Résiduel hors scope du diff, découvert en creusant le même angle** : `p2_sens_a` (NON touché
  par ce diff, l.239 `[ ! -e "$target" ]`) construit `$target` depuis une citation d'index NON
  sanitisée (`raw`, peut contenir `../`) et fait un test d'EXISTENCE sur ce chemin — vérifié par
  fixture : une citation `../../outside_target/leak.md` dans `refs/_index.md` détecte
  correctement qu'un fichier RÉEL hors du repo existe (aucune divergence signalée = oracle
  d'existence positif). C'est un oracle booléen d'existence de chemin arbitraire hors `$ROOT`,
  via un `_index.md` d'un dépôt cloné hostile — contredit directement le principe que le nouveau
  commentaire de P1 sens A invoque (« ADR-031 : ce gate ne lit rien hors sa cible »), mais ce
  principe n'est appliqué qu'à P1 dans ce correctif, pas symétriquement à P2. Absent du registre
  STRIDE des deux plans (29-02/29-04) — T-29-02-07 couvre un vecteur différent (chemin absolu
  RECOPIÉ dans le rapport, pas un ORACLE construit par traversée).

**Why retenir ceci** : le pattern « preuve fantôme » n'est pas un accident isolé — il a survécu à
un cycle de correction explicitement mandaté pour le fermer. Au prochain audit touchant ces
scripts, vérifier SYSTÉMATIQUEMENT que tout fixture de non-régression est rejoué contre le code
d'AVANT (`git show <parent>:chemin > old.sh`) et produit une sortie RÉELLEMENT différente — ne
jamais se fier au commentaire du test ni au verdict "0 ko" global. Voir aussi
[[feedback-execute-dont-trust-green]].

**How to apply** : au prochain passage sur `check-map-drift.sh`/`scaffold-docs.sh`, vérifier (1) si
le fixture « tiret initial » a été déplacé à la racine du dépôt fixture (pas sous `refs/`) et
reproduit réellement le crash sur l'ancien code ; (2) si `p2_sens_a` a reçu la même garde
« jamais lire hors $ROOT » que `p1_sens_a`, ou si le risque a été formellement dispositionné
(accept/mitigate) dans le registre STRIDE du plan.
