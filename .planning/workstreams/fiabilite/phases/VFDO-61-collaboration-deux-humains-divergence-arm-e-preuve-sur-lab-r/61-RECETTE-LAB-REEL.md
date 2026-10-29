# Phase 61 — Recette du lab réel (COLB-08)

**Statut : procédure livrée, jamais exécutée par la mission. Bloqueur humain : le lab et les deux humains restent à désigner par Samuel.** COLB-08 reste **décochée** tant que P61-B-01 (quel lab
réel, avec quels deux humains) et P61-B-02 (trois semaines d'usage réel après armement) ne sont pas levés. Cette
mission n'a joué aucune semaine de cette recette et n'écrit aucun compte rendu : la preuve de **mécanisme** est
automatisée (suite `test-divergence-deux-clones.sh`), la preuve d'**usage** est humaine. Seul Samuel coche COLB-08.

Mandat de rédaction : Samuel, /vf-auto session principale, 2026-10-29 (ne vaut pas arbitrage de fond).
Sources : P61-D-08, P61-D-09, P61-PL-05, P61-PL-16 ; critère 4 du jalon (« chaque divergence détectée par
`check-divergence.sh`, journalisée »).

## Prérequis

- Un lab **réel** désigné par Samuel (P61-B-01). Un clone jetable ne vaut pas recette.
- **Deux humains**, chacun sur son poste de travail, chacun avec **son propre clone** du même dépôt : l'un déclare le
  poste `product`, l'autre le poste `dev`.
- **Un seul workstream** partagé par les deux clones (jamais un workstream par rôle) ; ses dossiers
  `.planning/workstreams/<nom>/` (dont `phases/` et `ROADMAP.md`) sont **versionnés** : le relevé relit l'historique
  git, il ne voit que ce qui est suivi.
- VibeFlow **à la version qui porte la Phase 61**, installé et à jour sur les deux postes (`/vf-update`).
- Aucun `core.hooksPath` configuré, ni dans le clone ni au niveau global du poste. S'il l'est (husky, dossier de
  hooks partagé), l'armement est **refusé audiblement** : la ligne à ajouter à la main est imprimée par le refus, et
  l'armement est alors dit « à la main » (le relevé et son critère valent pareil).
- Git en ligne de commande, `bash` et `awk` disponibles ; le relevé ne modifie jamais le dépôt de travail.
- Trois semaines calendaires **consécutives** d'usage normal après l'armement. Aucune divergence n'est provoquée
  exprès : la recette observe le travail réel, elle ne le met pas en scène.

## Armement

Pour chaque clone, depuis sa racine :

1. Poser le poste et le filet par le chemin d'installation habituel (`/vibeflow-install`, ou l'engine à la main :
   `vibeflow-update.sh --role <product|dev> install <modules>`). Si le poste a été posé avant la version qui porte
   la Phase 61, le filet s'arme par `vibeflow-update.sh --scope project role <product|dev>` (une mise à jour
   rafraîchit un filet déjà posé, elle n'arme jamais un clone).
2. Retrouver le dossier du cache du plugin (celui que le hook embarque) :
   `S="$(sed -n "s/^VF_DIVERGENCE_SCRIPT='\(.*\)'$/\1/p" "$(git rev-parse --git-path hooks)/post-merge")"` puis
   `CACHE="$(cd "$(dirname "$S")/../.." && pwd -P)"`.
3. Contrôler l'état : `bash "$CACHE/conductor/scripts/vf-divergence-hook.sh" status --path .` doit rendre le code
   **0** (`HOOK post-merge ARME` et `HOOK post-rewrite ARME`, ou `ARME-A-LA-MAIN`). **Recopier cette sortie au
   compte rendu**, pour chacun des deux clones, avec la date : c'est le point de départ des trois semaines.
4. À chaque mise à jour du plugin (`/vf-update`), le chemin du filet est rafraîchi vers le nouveau cache ; vérifier
   de nouveau le code 0 de `status` et le noter.

Limites de couverture, mesurées (git 2.50.1) et écrites : le filet ne se déclenche **pas** sur `git reset --hard`,
`git switch` / `git checkout`, `git cherry-pick`, ni sur un `git rebase` qui ne réécrit aucun commit. Une fusion
faite sur la forge n'est vue qu'au `git pull` local suivant. `git commit --amend` se tait volontairement.
`git pull --rebase` avec commit local est couvert par `post-rewrite` ; `git pull`, `git merge` et `git pull --rebase`
sans commit local par `post-merge`.

## Relevé hebdomadaire

Une fois par semaine, **sur chaque clone**, chaque humain exécute le relevé ci-dessous. Il est joué tel quel par le
cas `D2C-RELEVE` de la suite à deux clones (avec son témoin `D2C-RELEVE-TEMOIN`, qui le fait rougir quand une ligne
de journal manque) : toute modification de ce bloc doit être faite dans le fichier de la recette, la suite le relit.

1. Archiver le journal du clone : `cp "$(git rev-parse --git-common-dir)/vf-divergence/journal.tsv" releve-<semaine>-<poste>.tsv`
   (le journal vit sous le dossier git commun, hors de l'arbre versionné ; absent tant qu'aucune divergence n'a été
   vue, ce qui n'est pas une erreur).
2. Enregistrer le script ci-dessous sous le nom `releve.sh`, **hors du clone** (par exemple dans le dossier personnel).
3. Le lancer : `bash releve.sh <chemin du clone> "$CACHE"`. Il liste les événements du reflog de type pull, merge et
   fin de rebase, rejoue `check-divergence.sh` (celui du cache, jamais celui de l'arbre) sur un worktree **détaché**
   de chaque événement, créé et retiré avec les hooks désactivés, puis apparie chaque événement divergent à une
   ligne du journal par son HEAD (champ 5).
4. Recopier la sortie au compte rendu : lignes `EVENEMENT <sha> <divergent|conforme|non-verifiable>`, puis
   `NON-VERIFIABLE <n>` et `SUBIE-EN-SILENCE <n>`. Le code de sortie est 1 si `SUBIE-EN-SILENCE` n'est pas 0.

<!-- releve:debut -->
```bash
#!/usr/bin/env bash
# releve.sh <clone> <dossier du cache du plugin>
# Rejoue check-divergence.sh sur chaque evenement de fusion du reflog et apparie les evenements
# divergents aux lignes du journal par leur HEAD. Lecture seule sur le depot de travail.
set -uo pipefail
export LC_ALL=C GIT_TERMINAL_PROMPT=0
clone="${1:-}"; cache="${2:-}"
[ -n "$clone" ] && [ -n "$cache" ] || { echo "usage : releve.sh <clone> <dossier du cache du plugin>" >&2; exit 64; }
chk="$cache/conductor/scripts/check-divergence.sh"
[ -f "$chk" ] || { echo "NON-VERIFIABLE : check-divergence.sh introuvable dans le cache : $chk" >&2; exit 2; }
gc="$(git -C "$clone" rev-parse --git-common-dir 2>/dev/null)" || { echo "NON-VERIFIABLE : $clone n'est pas un depot git" >&2; exit 2; }
case "$gc" in /*) : ;; *) gc="$clone/$gc" ;; esac
common="$(cd "$gc" 2>/dev/null && pwd -P)" || { echo "NON-VERIFIABLE : dossier git commun illisible" >&2; exit 2; }
journal="$common/vf-divergence/journal.tsv"
tmp="$(mktemp -d)" || { echo "NON-VERIFIABLE : dossier temporaire non cree" >&2; exit 2; }
trap 'rm -rf "$tmp"' EXIT
# 1. Evenements : pull, merge et fin de rebase (le sha est le HEAD du clone apres l'evenement), du plus recent
#    au plus ancien, sans doublon.
git -C "$clone" reflog show --format='%H%x09%gs' HEAD 2>/dev/null </dev/null | awk -F '\t' '
  $2 ~ /\(finish\)/ { if (!v[$1]++) print $1; next }
  $2 ~ /^(pull|merge)/ && $2 !~ /\((start|pick|continue|abort|squash|fixup|reword|edit|reset|drop)\)/ { if (!v[$1]++) print $1 }
' > "$tmp/evenements"
subie=0; nonverif=0; i=0
while IFS= read -r sha; do
  [ -n "$sha" ] || continue
  i=$((i + 1))
  wt="$tmp/wt$i"; verdict="non-verifiable"
  # 2. Worktree detache de l'evenement, hooks desactives ; check-divergence.sh du CACHE sur ce worktree.
  if git -C "$clone" -c core.hooksPath=/dev/null worktree add -q --detach "$wt" "$sha" >/dev/null 2>&1 </dev/null; then
    rc=0
    bash "$chk" --path "$wt" >/dev/null 2>&1 </dev/null || rc=$?
    case "$rc" in 0|3) verdict="conforme" ;; 1) verdict="divergent" ;; esac
    git -C "$clone" -c core.hooksPath=/dev/null worktree remove --force "$wt" >/dev/null 2>&1 </dev/null || rm -rf "$wt"
  fi
  # 3. Appariement : un evenement divergent doit avoir une ligne DIVERGENCE au journal portant son HEAD.
  case "$verdict" in
    divergent)
      if [ -f "$journal" ] && [ ! -L "$journal" ] \
         && awk -F '\t' -v h="$sha" '$3 == "DIVERGENCE" && $5 == h { c++ } END { exit (c == 0) }' "$journal"; then
        :
      else
        subie=$((subie + 1))
      fi ;;
    non-verifiable) nonverif=$((nonverif + 1)) ;;
  esac
  echo "EVENEMENT $sha $verdict"
done < "$tmp/evenements"
git -C "$clone" worktree prune >/dev/null 2>&1 </dev/null
echo "NON-VERIFIABLE $nonverif"
echo "SUBIE-EN-SILENCE $subie"
[ "$subie" -eq 0 ] || exit 1
exit 0
```
<!-- releve:fin -->

Lecture de la sortie :

- `EVENEMENT <sha> divergent` : la numérotation d'un compartiment divergeait dans l'arbre issu de cet événement
  (signaux S2, S4 ou S5 de `check-divergence.sh`). Il doit exister une ligne de journal `DIVERGENCE` avec ce HEAD.
- `EVENEMENT <sha> conforme` : rien à journaliser (le code 3 de `check-divergence.sh`, dépôt non partitionné, compte
  pour conforme).
- `EVENEMENT <sha> non-verifiable` : l'événement n'a pas pu être rejoué (commit disparu après un `gc`, worktree non
  créé). Jamais compté comme conforme ; à expliquer au compte rendu.
- `SUBIE-EN-SILENCE <n>` : nombre d'événements divergents **sans** ligne de journal. C'est la mesure de la recette :
  elle doit valoir **0** chaque semaine sur chaque clone.
- Une ligne `NON-VERIFIABLE` **au journal** (verdict du champ 3) est un contrôle que le hook n'a pas pu jouer
  (cache disparu, exécutable dans l'arbre, code inattendu) : la raison est au champ 7 ; à expliquer au compte rendu.

Limites du relevé : un événement qui échappe au filet par construction (voir « Armement », limites de couverture) et
qui rend l'arbre divergent apparaît comme `SUBIE-EN-SILENCE`. C'est voulu : la recette mesure ce que le filet manque
en usage réel, pas seulement ce qu'il attrape.

## Critère de passage

La recette est passée quand, **trois semaines consécutives après l'armement des deux clones** :

1. toute divergence observée dans l'historique git — tout événement du reflog rendu `divergent` par le relevé — est
   **présente au journal du clone où elle a atterri** ;
2. le relevé rend `SUBIE-EN-SILENCE 0` **chaque semaine, sur les deux clones** ;
3. chaque ligne `NON-VERIFIABLE` (relevé ou journal) est **expliquée** au compte rendu (cause, correction éventuelle) ;
4. l'état `status` des deux clones est resté à 0 pendant la période (ou chaque écart est expliqué et corrigé, la
   semaine concernée étant alors recomptée à partir de la correction).

Une semaine où rien n'a divergé est une semaine valable (`SUBIE-EN-SILENCE 0`, aucun événement `divergent`) : la
recette ne fabrique pas de divergence. Mais une recette où **aucune** divergence n'est survenue en trois semaines
prouve peu l'usage : Samuel décide alors s'il faut prolonger ou provoquer un cas contrôlé. Un événement `divergent`
sans ligne de journal (`SUBIE-EN-SILENCE` > 0) **n'est pas passé** : le remonter comme défaut du filet (jamais corrigé
dans le cadre de la recette, ADR-031).

## Gabarit de compte rendu

À remplir par les deux humains, à raison d'une ligne par semaine et par clone ; à déposer sous le nom
`61-RECETTE-COMPTE-RENDU.md` dans le dossier de phase.

Lab : _(nom, désigné par Samuel)_ · Humains : _(poste product : …, poste dev : …)_ · Workstream : _(nom)_ ·
Version de VibeFlow : _(à l'armement)_ · Armement : _(date, sortie de `status` recopiée, par clone)_.

| Semaine | Clone (poste) | Événements | Divergents | Lignes de journal | Subies en silence | Non vérifiables | Observations |
|---|---|---|---|---|---|---|---|
| 1 | product | | | | | | |
| 1 | dev | | | | | | |
| 2 | product | | | | | | |
| 2 | dev | | | | | | |
| 3 | product | | | | | | |
| 3 | dev | | | | | | |

Conclusion : _(passé / non passé, selon le critère ci-dessus ; défauts remontés)_ · Signé : _(les deux humains)_.

## Clôture

- **Déclencheur** : le compte rendu `61-RECETTE-COMPTE-RENDU.md` est déposé dans le dossier de phase, complet
  (six lignes de relevé, sorties de `status`, explications des `NON-VERIFIABLE`).
- **Qui coche** : seul Samuel coche COLB-08 dans `.planning/workstreams/fiabilite/REQUIREMENTS.md`, après lecture du
  compte rendu. Ni la mission, ni un manager, ni la suite automatisée ne le font à sa place.
- **Tant que cela n'est pas fait** : COLB-08 reste décochée (P61-B-01, P61-B-02). La preuve de mécanisme (COLB-07) ne
  vaut jamais preuve d'usage ; cette recette n'a pas été jouée.
