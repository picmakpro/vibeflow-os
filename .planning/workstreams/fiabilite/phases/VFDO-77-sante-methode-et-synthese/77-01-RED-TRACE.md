AVANT 9c495e543dce9fc1b1d83b0a60dc443f0306f073

# 77-01 — trace du rouge (témoins posés avant tout code des gates ; suites jouées sur la copie figée du gate à la base)

## Base du rouge

Le rouge est mesuré sur la copie figée de chaque gate (`check-method-budget-pre-4a246c4c.sh`, `check-instruction-budget-pre-394c7956.sh`), posée à la place du gate dans une copie de l'arbre du module : c'est le code d'avant le plan.
Commande : `bash scripts/tests/test-check-method-budget.sh` (depuis `plugin/conductor` de la copie), puis `bash scripts/tests/test-check-instruction-budget.sh` (copie construite avec `plugin/_internal`, pour `resolve-deps.sh`).
Méthode : `AVANT` ci-dessus ; les gates à `AVANT` sont les copies figées (aucun commit n'a touché les deux gates depuis `4a246c4c` et `394c7956`).

- Suite du gate de méthode : `Résultats : 559 PASS / 35 FAIL`, rc=1, 166 s.
- Suite du gate de densité : `== resultat : 74 ok, 12 ko ==`, rc=1, 31 s : 8 `✗` en section TI (TI1 à TI7, TI9) et 4 `✗` de mutants non opposables à la base (MI2, MI3, MI4, MI6 : la ligne visée n'existe pas encore).
- Hors périmètre du plan, rouge propre à la copie : `KL1` (« le .gitignore du dépôt source couvre le dossier de verrou ») — la copie de l'arbre n'est pas un dépôt qui porte le `.gitignore` du dépôt source ; vert dans l'arbre réel.

## Rouges sur la base (assertion, attendu, obtenu)

Gate de méthode (option inconnue : `[budget] argument inconnu : --format=tsv`, rc 64, sortie standard vide) :

- **TF1** `--format=tsv` rend 0 et la première ligne vaut `#vf-budget@1<TAB>check-method-budget` — attendu rc 0 et l'en-tête — obtenu rc 64, aucune ligne
- **TF2** six champs, types, unités et verdicts de la liste fermée — attendu `ecarts=0` — obtenu `ecarts=vide lignes=0` (un ensemble vide ne passe pas)
- **TF3** les huit types sur la fixture riche — attendu les huit — obtenu aucun
- **TF4** aucun champ absolu — attendu `absolus=0` — obtenu `absolus=vide` (vide : rouge, pas vert à vide)
- **TF5** (cinq sous-cas) autant de lignes TSV que de lignes de mesure du texte — attendu `n=3` (state), `n=4` (backlog), `n=1` (roadmap, memory-index, worktrees) — obtenu `n=0` chacun
- **TF6** `VF_STATE_BUDGET_KB=1`, budget 1 sur les lignes `state`, au moins une lue — attendu `budget1=ok(…)` — obtenu `budget1=non(0/0)`
- **TF7** P77-D-23, valeur la plus haute — attendu `prose=5/OK entree=45/DEPASSE` — obtenu `prose= entree=`
- **TF8** (deux sous-cas) le refus d'une option d'écriture dit « lecture seule » ; le refus d'un autre format dit « format inconnu : json » — attendu les deux messages — obtenu `argument inconnu` (rc 64 déjà vrai, sortie vide déjà vraie : les assertions de code et de sortie sont vertes à la base, ce sont les messages qui rougissent)
- **TF10** `--format=tsv` sans `--no-remote` n'appelle jamais le faux `gh`, avec des lignes de mesure rendues — attendu `gh=absent` — obtenu `gh=vide`
- **TF11** `--format=tsv` ne lance aucun verbe de rangement, avec des lignes de mesure rendues — attendu `verbes=[]` — obtenu `verbes=vide`
- **TF13** toute ligne de la sortie standard est l'en-tête ou une ligne à six champs — attendu `bad=0` — obtenu `bad=1` (l'en-tête manque : la première ligne vide n'est pas l'en-tête)

Gate de densité (option inconnue : `[check-instruction-budget] argument inconnu : --format=tsv`, rc 64) :

- **TI1** même rc que le texte et en-tête `#vf-budget@1<TAB>check-instruction-budget` — attendu rc 3 et l'en-tête — obtenu rc 64, aucune ligne
- **TI2** agents 250/251/301 lignes : `OK`, `AVERTISSEMENT`, `DEPASSE`, budget 300 — attendu les trois lignes — obtenu aucune
- **TI3** skills 500/501 : `OK`, `DEPASSE`, budget 500 — obtenu aucune
- **TI4** `socle` et `socle-baseline` (`EGALE`, `AU-DESSUS`, `EN-DESSOUS`, absence de ligne de baseline) — obtenu aucune ligne
- **TI5** lab tiers en TSV : en-tête et trois lignes `NON-APPLICABLE` sans valeur, rc 2 — obtenu rc 64, aucune ligne (la sonde positive du mode texte, elle, est verte : sortie vide, message, rc 2)
- **TI6** aucun champ absolu, avec au moins une ligne de mesure — attendu `absolus=0` — obtenu `absolus=vide`
- **TI7** aucune ligne de rapport texte, au moins une mesure — obtenu `mesures=0`
- **TI9** `--format=json` : rc 64, sortie vide, message « format inconnu » — attendu le message — obtenu `argument inconnu`

## Verts sur la base et leur raison

- **TF4 / TI6, sondes positives** : la sortie texte de la même fixture porte la racine absolue ; elles prouvent que la sonde sait voir un chemin absolu. Les assertions « aucun champ absolu » sont, elles, rouges à la base (ensemble vide exclu) ; MF4 et MI6 prouvent qu'elles rougissent sur un chemin absolu émis.
- **TF9** lecture seule : vert à la base parce que rien n'est émis ni écrit (témoin vacant) ; sa sonde positive (`--auto` en mode texte modifie l'arbre de la même fixture) et MF1 prouvent qu'il sait rougir.
- **TF12 / TI8** A/B texte contre la copie figée : verts, le gate à la base EST la copie figée ; MF7 et MI5 prouvent qu'ils rougissent sur un libellé changé.
- **TF8** (codes et sortie vide), **TF10 et TF11 sondes positives**, **TI5 sonde positive**, **X8**, **X9** : verts à la base, aucune ligne ajoutée.
- **MF1..MF8 et MI1..MI6** : non opposables à la base (la ligne visée n'existe pas, `bash -n` ou « ligne introuvable ») : un mutant sans effet est un échec, ce qui est voulu ; ils sont joués sur le code livré (sections « Mutants rouges obtenus »).

## Cibles de mutants existants (aucune ne doit être retirée ni modifiée par ce plan, Pitfall 2)

Relevé exécutable : la suite du gate de méthode, instrumentée pour journaliser chaque ligne exacte que `make_mutant` vise, jouée une fois ; les mutants de densité par la lecture de leurs variables `MUT*_OLD`. Seules sont gardées les lignes qui existent dans la copie figée du gate (les cibles que ce plan ajoute lui-même, MF et MI, sont exclues). Les lignes visées par les sept bascules de l'étape `check-instruction-budget` du workflow sont couvertes autrement : le plan ne modifie pas `ci.yml` (`git diff` vide sur ce fichier, mesuré dans la tâche 3).

CIBLE          && git -C "$repo" merge-base --is-ancestor "refs/heads/$own" "$base" 2>/dev/null; then
CIBLE       "$bshort") continue ;;
CIBLE       HEAD) continue ;;
CIBLE       OVER=1; flag "RANGEABLE stash : $sha « $msg »"
CIBLE       OVER=1; flag "À VALIDER branche distante : $ref (PR #$pr, $(printf '%s' "$auths" | cut -f1 | sed -n 1p)) — suppression = geste humain"
CIBLE       if [ -z "$origin_url" ]; then
CIBLE       is_owner "$a" || n=1
CIBLE       vf_ws_resolve "$ROOT/.planning"; names="${VF_WS_NAME:-}"
CIBLE     [ "${f##*/}" = MEMORY.md ] && continue
CIBLE     auths=$(printf '%s\n' "$tsv" | NAME="$name" awk -F'\t' '$1 == ENVIRON["NAME"] && $5 == "false" { print $3 "\t" $2 }')
CIBLE     case "$short" in origin/*) name="${short#origin/}" ;; *) say "branche distante $short : hors du remote origin, jamais candidate"; continue ;; esac
CIBLE     case ",$PROTECTED_WS," in
CIBLE     elif [ -n "$base" ] && is_worked "$repo" "$own" \
CIBLE     if (hist && lev > hlev) { mv($0); next }
CIBLE     if printf '%s\n' "$tsv" | NAME="$name" awk -F'\t' '$4 == ENVIRON["NAME"] { f = 1 } END { exit !f }'; then
CIBLE     is_longlived "$b" && { say "branche $b : par défaut ou longue durée, jamais candidate"; continue; }
CIBLE     main|master|develop|dev|development|trunk|staging|production|prod|stable|release/*|releases/*) return 0 ;;
CIBLE     say "STATE ok : $f fait $kb Ko (budget $STATE_KB Ko)"
CIBLE   [ "$(git -C "$1" reflog show --format=%H "refs/heads/$2" -- 2>/dev/null | grep -c .)" -gt 1 ]
CIBLE   [ "$AUTO" -eq 0 ] || max=0   # --auto : jamais d attente (un Stop ne se bloque pas 10 s par fichier)
CIBLE   [ "$DRY" -eq 0 ] || return 0   # --dry-run : la décision est prise (et ses refus dits), rien n'est écrit
CIBLE   [ "$rc" -eq 0 ] || { UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : git for-each-ref --merged $base a échoué (rc $rc)"; return 0; }
CIBLE   [ "$rc" -eq 0 ] || { UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches locales : git for-each-ref --merged $base a échoué (rc $rc)"; return 0; }
CIBLE   [ -z "$(LC_ALL=C comm -23 "$TMPD/p0" "$TMPD/p1")" ] || { archive_refuse "$rel : un pointeur d'un archivage précédent a disparu, rien déplacé"; return 0; }
CIBLE   awk 'index($0, "<!-- vf-archive: ") != 1' "$TMPD/snap" | LC_ALL=C sort > "$TMPD/m0"
CIBLE   case "$json" in *[![:space:]]*) ;; *) UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : gh pr list n'a rien rendu (sortie vide, rc 0)"; return 0 ;; esac
CIBLE   case "$want" in */*) ;; *) UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : remote.origin.url absent ou illisible (« $origin_url »), dépôt des PR non comparable"; return 0 ;; esac
CIBLE   cat "$TMPD/arch" > "$ROOT/$archrel" && cmp -s "$ROOT/$archrel" "$TMPD/arch" \
CIBLE   cmp -s "$TMPD/m0" "$TMPD/m1" || { archive_refuse "$rel : preuve des lignes conservées en échec, rien déplacé"; return 0; }
CIBLE   elif ! git -C "$repo" rev-parse -q --verify "$base^{commit}" >/dev/null 2>&1; then UNVERIFIABLE=1; flag "NON VÉRIFIABLE rangement : la branche de référence $base ne désigne aucun commit dans $repo (origin/HEAD orphelin ?) : worktrees, branches, stash et branches distantes non classés"; base=""
CIBLE   if ! archive_lock; then
CIBLE   if ! cmp -s "$src" "$TMPD/snap"; then
CIBLE   if (ispointer($0) || $0 ~ /^Phase:/) { pr($0); next }
CIBLE   if (shipped(sum) && held != "") {
CIBLE   if [ "$(printf '%s' "$have" | tr '[:upper:]' '[:lower:]')" != "$(printf '%s' "$want" | tr '[:upper:]' '[:lower:]')" ]; then
CIBLE   if [ "$DRY" -eq 1 ]; then archive_one_locked "$@"; return 0; fi   # photographie : ni verrou, ni écriture
CIBLE   if [ -z "$base" ]; then UNVERIFIABLE=1; flag "NON VÉRIFIABLE rangement : branche de référence introuvable dans $repo (ni origin/HEAD, ni main, ni master) : worktrees, branches, stash et branches distantes non classés"
CIBLE   if why=$(src_unclean "$rel"); then archive_refuse "$rel $why, rien déplacé"; return 0; fi
CIBLE   json=$(cd "$repo" && "$GH_BIN" pr list --state merged --limit "$PR_LIMIT" --json headRefName,number,author,baseRefName,isCrossRepository 2>/dev/null); rc=$?
CIBLE   return (w == "CLOS" || w == "RÉSORBÉ" || w == "ADOPTÉ" || w == "ADOPTÉE")
CIBLE   targets="racine|$ROOT/.planning"
CIBLE   trunc=0; [ "$nprs" -ge "$PR_LIMIT" ] && trunc=1
CIBLE "*) continue ;; esac
CIBLE function ishist(h) { return (tolower(h) ~ /historique|history|d..?cisions|decisions|journal|performance metrics|point du/) }
CIBLE function mv(l) { if (!ptr) { pr("<!-- vf-archive: " ARCHREL " -->"); ptr = 1 } print l > ARCH; n++ }
CIBLE function shipped(t) { return (t ~ /✅/ || t ~ /SHIPPED/) }
CIBLE       } else if ($0 ~ /^[ \t]/) {
CIBLE     [ "$instr" -gt "$bl_instr" ] && instr_over=1
CIBLE     [ "$lines" -gt "$bl_lines" ] && verdict="${verdict}+LIGNES-EN-HAUSSE"
CIBLE     verdict="${verdict}+AVERTISSEMENT-ADR029"
CIBLE   find "$d" '(' -type d -name '.*' -prune ')' -o '(' -type d -name '*-references' -prune ')' -o '(' -type f -name SKILL.md -print ')' -o '(' -type l -name SKILL.md -print ')' 2>/dev/null | while IFS= read -r f; do
CIBLE   if [ "$BOOTSTRAP_HAS_BASELINE" -eq 1 ] && [ "$BOOTSTRAP_TOKENS" -gt "$BOOTSTRAP_BASELINE_VALUE" ]; then
CIBLE   if [ "$fm_state" = "open" ]; then
CIBLE   if [ "$lines" -gt "$VF_BUDGET_LINE_CAP" ]; then
CIBLE   if [ "$lines" -gt "$VF_SKILL_LINE_CAP" ]; then
CIBLE   if [ "$verdict" != "DEPASSEMENT-ADR029" ] && [ "$lines" -ge "$VF_BUDGET_LINE_WARN_FROM" ] && [ "$lines" -le "$VF_BUDGET_LINE_CAP" ]; then
CIBLE   if [ -f "${d}module.json" ] && grep -Eq '"type"[[:space:]]*:[[:space:]]*"doc-only"' "${d}module.json" 2>/dev/null; then
CIBLE [ -f "$SENTINEL" ] && ARMED=1

## Mutants rouges obtenus (sur le code livré)

Chaque mutant change le script (vérifié par `cmp`), passe `bash -n`, et rougit l'assertion qu'il vise ; un mutant sans effet est un échec de la suite.

Gate de méthode (suite : `594 PASS / 0 FAIL`) :

- **MF1** `AUTO=1` forcé en mode TSV : TF9 rougit — obtenu `arbre=modifie`
- **MF2** passe de rangement rétablie en mode TSV : TF11 rougit — obtenu `verbes=[[for-each-ref][ls-files][stash]]`
- **MF3** type `state` renommé `etat` : TF2 rougit — obtenu `ecarts=3 lignes=21`
- **MF4** chemin absolu émis : TF4 rougit — obtenu `absolus=3`
- **MF5** `--no-remote` implicite ET passe de rangement retirés : TF10 rougit — obtenu `gh=appele`
- **MF6** valeur la plus haute retirée (STATE et BACKLOG) : TF7 rougit — obtenu `prose=0/OK entree=0/OK`
- **MF7** libellé d'un `say` changé : TF12 rougit — obtenu `diff=3/34`
- **MF8** budget en dur en mode TSV : TF6 rougit — obtenu `budget1=non(3/0)`

Gate de densité (suite : `86 ok, 0 ko`) : **MI1** bord d'avertissement décalé (TI2), **MI2** valeur `0` en lab tiers (TI5, `mauvais=1`), **MI3** `NON-VERIFIABLE` au lieu de `NON-APPLICABLE` (TI5, `mauvais=1`), **MI4** relation de baseline inversée (TI4), **MI5** ligne du rapport texte changée (TI8, `diff=73/75`), **MI6** chemin absolu émis (TI6, `absolus=1`). Tous tués.

## La mesure de non-modification des cibles tient une cible qui commence par « - » (consigne de la session principale)

La mesure du plan lit les lignes RETIRÉES d'un `git diff -U0`. Une ligne retirée dont le texte commence par `-` y apparaît en `--…`, et l'en-tête de fichier est `--- a/…` : la forme `sed -n 's/^-\([^-].*\)$/\1/p'` écarte les deux (second caractère `-`) et laisserait passer, sans bruit, le retrait d'une cible qui commence par `-`.
La mesure retenue lit le diff par hunk (awk : une ligne `diff --git` ouvre l'en-tête, la première `@@` le ferme ; hors en-tête, toute ligne commençant par `-` est du contenu retiré, rendu sans son premier caractère), puis `grep -qxFf` contre les `CIBLE` :

`( AVANT=$(awk '$1=="AVANT"{print $2; exit}' <trace>) && [ -n "$AVANT" ] && git rev-parse --verify -q "$AVANT^{commit}" > /dev/null && T=$(mktemp) && trap 'rm -f "$T"' EXIT && sed -n 's/^CIBLE //p' <trace> > "$T" && [ -s "$T" ] && X=$(git diff -U0 "$AVANT" HEAD -- <gates> .github/workflows/ci.yml) && ! { printf '%s\n' "$X" | awk '/^diff --git/ { h = 1; next } /^@@/ { h = 0; next } !h && /^-/ { print substr($0, 2) }' | grep -qxFf "$T"; } )`

Sonde, dépôt jetable, une cible `-h) usage ;;` (commence par `-`) et une cible `  cible normale`, sous bash ET sous zsh (mêmes codes) :

- cibles intactes : 0
- cible commençant par `-` retirée, forme awk : **1** ; la forme `sed` du plan, sur le même cas : **0** (cible ratée : c'est la raison du changement de forme)
- cible ordinaire retirée : 1
- ligne de contenu `--- a/fake` ajoutée puis retirée (pas une cible) : 0, elle n'est pas prise pour un en-tête
- trace sans ligne `CIBLE` : 1 ; `AVANT` vide : 1 ; `AVANT` invalide : 1
Sur ce plan : les 58 cibles relevées sont intactes depuis `AVANT` (code 0), `.planning/instruction-budget-baselines.tsv`, `plugin/conductor/VERSION`, `VERSION` et `.github/workflows/ci.yml` ne figurent dans aucun diff de la plage.
