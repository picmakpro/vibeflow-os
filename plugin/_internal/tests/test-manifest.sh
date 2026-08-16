#!/usr/bin/env bash
# test-manifest.sh — Suite du socle manifeste de pose (Phase 31, MANI-01/D-31-01/02/03/09/11).
#
# Fixtures :
#   - software-architecture (SKILL.md + rules/ + references/ + scripts/ + scripts/tests/ +
#     hooks/hooks.json). Aucun sous-processus de régime C (pas d'AGENT.md, pas d'agents/, pas de
#     scripts/seed-registres.sh ni scripts/ensure-design-deps.sh) — même fixture que 31-04 (MANI-02).
#     T1-T6, T6b (fixture .txt injecté dans le CACHE de test), T9, T11-T13, T15, TD1, TD3, TD8,
#     TD11, TD12, TD13.
#   - skill-creator (skills imbriqués posés par cp -r, AGENT.md). T7, T7b, T9b, T9c, T10, TD7.
#   - reference (module doc pur, content/ seul). T8, TD6.
#   - dev-orchestrator (AGENT.md + build-gsd-index.sh + build-gsd-capabilities-index.sh, régime A
#     RÉEL, mesuré sur pièce). TD2.
#   - consolidator (scripts/seed-registres.sh, régime C RÉEL). TD4, TD5.
#   - consolidator + software-architecture (cache à DEUX modules à hooks.json, ordre alphabétique).
#     TD9 (multi-module), TD10.
#
# T1 — après install software-architecture (scope project, lab neuf), le manifeste
#      .claude/scripts/.vibeflow-manifest-software-architecture existe et contient la ligne
#      EXACTE skills/software-architecture/SKILL.md (D-31-01). Égalité de ligne (awk), pas
#      sous-chaîne : ".claude/skills/software-architecture/SKILL.md" (chemin NON relativisé, la
#      mutation qui a fait tomber vf_rel_to_target) CONTIENT le chemin correct — un `grep -qF`
#      passerait à tort dessus (B-2, revue vague 1).
# T2 — aucune ligne du manifeste ne se termine par une barre oblique (grain fichier, D-31-02).
# T3 — aucune ligne du manifeste ne commence par une barre oblique (zéro chemin absolu, D-31-02).
#      Scope project SEULEMENT : TARGET_ROOT="./.claude" y est déjà relatif, donc un chemin non
#      relativisé n'y est jamais absolu — cette assertion ne peut PAS rougir sur ce scope seul.
# T3b — même garde en scope `user` (TARGET_ROOT="$HOME/.claude", absolu) : seul scope où une
#      régression de relativisation peut réellement produire une ligne "/…" (B-2, revue vague 1).
# T4 — le manifeste est trié LC_ALL=C et sans doublon (LC_ALL=C sort -u == fichier, D-31-02).
# T4b — même garantie au grain UNITÉ (D-31-12) : source les fonctions, vf_record plusieurs
#      chemins non triés + un doublon, vf_manifest_flush, assère l'ordre/dédup — sans attendre
#      qu'un manifeste multi-lignes existe de bout en bout (31-03). Un manifeste d'UNE ligne
#      rend le tri identitaire : T4 seul ne peut pas rougir sur une mutation qui casse le tri.
# T5 — le manifeste ne contient aucune entrée de la liste close d'exclusions D-31-03 (ni
#      scripts/vf-portable.sh, ni scripts/.vibeflow-installed, ni une ligne
#      scripts/.vibeflow-manifest-…).
# T5b — même liste au grain UNITÉ (D-31-12) : appelle vf_manifest_excluded directement sur les 5
#      motifs (doivent matcher) ET sur des chemins voisins (ne doivent PAS matcher, anti-sur-
#      blocage) — sans site de pose exerçant réellement la liste aujourd'hui, T5 seul est vacant
#      (aucun chemin observé n'atteint la liste, cf. mutation `return 1` restée verte en revue).
# T6 (31-03) — EXHAUSTIVITÉ : après migration des ~35 sites (tâche 2), l'ensemble des lignes du
#      manifeste est EXACTEMENT l'ensemble des fichiers créés sous $LAB/.claude, moins la liste
#      close d'exclusions (dont settings*.json, fichiers MERGÉS et non posés). Comparaison par
#      `comm` sur listes triées LC_ALL=C, aucune exception négociée au-delà de la liste déclarée.
# T7 (31-03) — grain fichier sur un cp -r (D-31-02) : le module skill-creator (skills imbriqués)
#      produit une ligne par fichier posé, jamais une ligne de répertoire.
# T7b (31-03) — gel des dotfiles de premier niveau (D-31-11 point 2) : un fichier caché injecté à
#      la racine d'un skill_dir copié par cp -r n'apparaît NI sur disque NI dans le manifeste —
#      comportement figé, pas corrigé (remontée §7 n°4 du cadrage).
# T8 (31-03) — asymétrie docs/ (D-31-03) : le module reference (content/ seul) pose bien
#      docs/reference/… sur disque, et le manifeste ne contient AUCUNE ligne docs/.
# T9 (31-03) — même liste close d'exclusions D-31-03 que T5, sur le fixture plus riche de T6.
# T9b (31-03) — copie dégradée journalisée (D-31-11 point 4) : collision fichier/répertoire forcée
#      sur UNE entrée d'un cp -r — la pose n'échoue PAS, le chemin en collision est journalisé sur
#      stderr et absent du manifeste, le reste de la pose est intact.
# T9c (31-03) — trou de silence rattrapé (D-31-11 point 4 §Complément, W-2) : un skill_dir source
#      entièrement illisible fait échouer le cp -r sans qu'aucun dest_file ne soit détecté manquant
#      (énumération vide) — une ligne de compte rendu apparaît malgré tout.
# T6b (M3, revue 31-03) — fixture .txt injecté dans le CACHE de test (jamais dans le module réel)
#      pour exercer le site #3 (copy_module_scripts, boucle scripts/*.txt), jamais atteint par T6
#      seul (T6 est AVEUGLE à un site cassé des DEUX côtés — rien à comparer). Existence positive
#      sur disque ET ligne exacte au manifeste. Discriminance prouvée par mutation du routage.
# T10-T13 (B1-B4, D-31-13, revue 31-03) — injection de panne RÉELLE (chmod 000) sur les quatre
#      sites où la migration avait réduit une chaîne tolérante à un appel nu de helper en position
#      finale de boucle : `install` s'avortait (rc=1) sur UN SEUL fichier illisible avant correctif.
#      T10 = vf_place_tree (sous-répertoire niché) ; T11 = rules/*.md ; T12 = scripts/tests/*.sh ;
#      T13 = scripts/*.sh. Chacun assure rc=0 + trace « copie dégradée ».
# T14/T14b (M2, revue 31-03) — vf_place_tree ne crie plus À TORT sur un répertoire source vide
#      mais lisible (T14), tout en continuant de crier sur un répertoire réellement illisible
#      (T14b, contre-épreuve anti-sur-correction).
# T15 (M6, revue 31-03) — uninstall retire le manifeste .vibeflow-manifest-<mod> (pas de module
#      fantôme laissé pour la découverte par glob de 31-05/31-07).
# T16 (M5, revue 31-03) — settings.json/settings.local.json dans le point UNIQUE
#      vf_manifest_excluded (D-31-03), grain unité.
#
# TD1-TD8 (31-04, MANI-02, D-31-04) — preuves du flag --dry-run. NOMMAGE : le 31-04-PLAN.md
#      désignait ces cas T10/T10b/T11/T12/T13/T13b/T13c/T14, MAIS ces noms sont déjà pris par les
#      cas B1-B4/M2/M6 de 31-03 ci-dessus (injection de panne réelle, gel des dotfiles côté pose)
#      — les réutiliser aurait ÉCRASÉ des cas discriminants existants sous les mêmes libellés.
#      Renommés TD<n> (Test Dry-run) en conservant l'ordre et l'intention du plan :
# TD1 (= T10 du plan) — ÉGALITÉ TOTALE, fixture software-architecture (aucun régime C) : dry-run
#      install == pose réelle, ensemble de chemins identique, AUCUNE exception négociée (D-31-04).
#      Trois mktemp -d disjoints (LAB_PLAN, LAB_REEL, CACHE — jamais le cache sous un lab).
# TD2 (= T10b) — RÉGIME A, discriminance : dev-orchestrator (AGENT.md + les 2 générateurs
#      d'index, mesuré sur pièce) annonce ses 3 lignes malgré l'absence de toute destination sur
#      disque (lab vierge) — preuve du piège de garde côté SOURCE. Assertion de présence, pas
#      d'égalité (dev-orchestrator déclenche aussi inject-mcp-tools.sh, régime C).
# TD3 (= T11) — ARBRE INCHANGÉ : empreinte find du lab ENTIER (scope local, couvre aussi
#      ./.gitignore) identique avant/après --dry-run (D-31-06).
# TD4 (= T12) — RÉGIME C, discriminance : consolidator (scripts/seed-registres.sh réel) annonce
#      une ligne mentionnant seed-registres.sh et le marqueur de non-énumération. Présence, pas
#      égalité (prétention distincte de TD1, D-31-04).
# TD5 (= T13) — exclusion D-31-03 côté MANIFESTE pour régime C : après un install RÉEL de
#      consolidator, le manifeste ne contient AUCUNE ligne memory/. F-08 (correction ciblée 31-04,
#      revue) : légende corrigée — TD5 seule NE PROUVE PAS l'asymétrie plan/manifeste complète
#      (elle ne rougit pas sous « memory/* retiré de vf_manifest_excluded » seul, cette mutation
#      est couverte par T5b ; TD5 rougit sous une mutation COMBINÉE memory/*+manifest_reset).
#      L'asymétrie plan/manifeste (le plan ANNONCE memory/, le manifeste ne le CONTIENT jamais)
#      est la conjonction TD4 (moitié « annoncé au plan ») + TD5 (moitié « absent du manifeste
#      réel ») — TD5 seule ne porte que la seconde moitié.
# TD6 (= T13b) — asymétrie docs/, moitié « présent au plan » (ferme la moitié manquante de
#      31-03/T8) : module reference (content/ seul), --dry-run annonce AU MOINS une ligne
#      docs/reference/.
# TD7 (= T13c) — gel des dotfiles, moitié « absent du plan » (symétrique de 31-03/T7b) : fixture
#      skill-creator + .hidden-marker injecté à la racine d'un skill_dir — AUCUNE ligne
#      .hidden-marker au plan.
# TD8 (= T14) — refus bruyant : --dry-run uninstall <mod> sort 1, rien supprimé (D-31-06).
#
# TD9-TD13 (correction ciblée 31-04, findings fusionnés revue + vérification) :
# TD9 (F-01) — MULTI-MODULE : install --all --dry-run sur cache à 2 modules à hooks.json annonce
#      autant de backups settings.json que la pose réelle en crée (garde disque aveugle à l'effet
#      d'un module antérieur du MÊME run, invisible d'un fixture mono-module comme TD1).
# TD10 (F-02) — update --all --dry-run, version inchangée : 0 ligne + porte le suffixe `( —)`.
# TD11 (F-04) — verbe de .vibeflow-installed sur lab vierge : `+`, jamais `~`.
# TD12 (F-06) — --dry-run=true : rc=1 nommé, message distinct du fourre-tout d'usage générique.
# TD13 (couverture manquante) — --scope user : chemin du plan absolu et résolu (fakehome),
#      aucune écriture (D-31-06).
#
# T0 — anti-vert-à-vide (contrat F13) : la suite compte ses propres assertions exécutées et
#      échoue si le total (pass+fail) est 0.
#
# Convention : asserts numérotés, helpers ok()/ko()/skip(), garde stricte mais jamais -e (la
# suite doit compter ses KO, pas avorter dessus), exit 1 si au moins un KO, exit 1 si
# pass+fail == 0. Calqué sur test-vibeflow-update.sh. T4b/T5b sourcent l'engine dans un
# sous-shell isolé ($(...)) : le sourcing hérite de `set -euo pipefail`, incompatible avec la
# convention "jamais -e" de cette suite — le sous-shell le confine, seul son verdict texte
# ("PASS"/"FAIL:…") en sort, jamais son `set -e`.

set -uo pipefail

# Racines (test sous _internal/tests/ → engine et modules sous _internal/.. = REPO).
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
INTERNAL_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REPO="$(cd "$INTERNAL_DIR/.." && pwd)"
INSTALLER="$INTERNAL_DIR/vibeflow-update.sh"

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

# grep insensible à l'alias zsh (ugrep) : on force le binaire système.
GREP="$(command -v grep)"

echo "== test-manifest (engine: $INSTALLER) =="

# Helper : prépare un cache de test avec un module copié depuis le repo.
prepare_module() {
  local cache="$1" mod="$2"
  mkdir -p "$cache/$mod"
  cp -r "$REPO/$mod/." "$cache/$mod/" 2>/dev/null || return 1
  [ -f "$cache/$mod/VERSION" ] || return 1
  return 0
}

# ---------------------------------------------------------------------------
# T1-T5 : install software-architecture dans un lab neuf, un seul manifeste vérifié
# sous 5 angles distincts.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
if prepare_module "$CACHE" "software-architecture"; then
  # M3 (revue 31-03) : le module réel software-architecture n'a AUCUN scripts/*.txt — sans ce
  # fixture, T6 (exhaustivité disque==manifeste) ne pouvait jamais rougir sur une régression du
  # site #3 (copy_module_scripts, boucle scripts/*.txt). Fichier injecté dans la copie de CACHE
  # uniquement — jamais dans le module réel du dépôt.
  printf 'known-versions fixture\n' > "$CACHE/software-architecture/scripts/known-versions.txt"
  (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install software-architecture >/dev/null 2>&1)
  MANIFEST="$LAB/.claude/scripts/.vibeflow-manifest-software-architecture"

  # T1 — présence + contenu EXACT (B-2, revue vague 1) : égalité de ligne via awk, pas une
  # sous-chaîne via grep -qF — ".claude/skills/software-architecture/SKILL.md" (mutation qui
  # supprime la relativisation) CONTIENT "skills/software-architecture/SKILL.md" et passerait
  # à tort un test de sous-chaîne.
  if [ -f "$MANIFEST" ] && awk '$0=="skills/software-architecture/SKILL.md"{f=1} END{exit !f}' "$MANIFEST"; then
    ok "T1 : manifeste présent, contient (ligne exacte) skills/software-architecture/SKILL.md"
  else
    ko "T1 : manifeste absent ou ne contient pas la ligne EXACTE skills/software-architecture/SKILL.md ($MANIFEST)"
  fi

  # T2 — aucune ligne de type répertoire (terminée par /)
  if [ ! -f "$MANIFEST" ]; then
    ko "T2 : manifeste absent, ligne répertoire non vérifiable"
  elif "$GREP" -qE '/$' "$MANIFEST"; then
    ko "T2 : au moins une ligne du manifeste se termine par une barre oblique (ligne répertoire)"
  else
    ok "T2 : aucune ligne du manifeste ne se termine par une barre oblique"
  fi

  # T3 — zéro chemin absolu
  if [ ! -f "$MANIFEST" ]; then
    ko "T3 : manifeste absent, chemin absolu non vérifiable"
  elif "$GREP" -qE '^/' "$MANIFEST"; then
    ko "T3 : au moins une ligne du manifeste commence par une barre oblique (chemin absolu)"
  else
    ok "T3 : aucune ligne du manifeste ne commence par une barre oblique"
  fi

  # T4 — trié LC_ALL=C, sans doublon
  if [ -f "$MANIFEST" ]; then
    SORTED="$(LC_ALL=C sort -u "$MANIFEST")"
    RAW="$(cat "$MANIFEST")"
    if [ "$SORTED" = "$RAW" ]; then
      ok "T4 : manifeste trié LC_ALL=C, sans doublon"
    else
      ko "T4 : manifeste NON trié ou avec doublon(s) — LC_ALL=C sort -u diverge du fichier"
    fi
  else
    ko "T4 : manifeste absent, tri non vérifiable"
  fi

  # T5 — aucune entrée de la liste close d'exclusions D-31-03
  if [ ! -f "$MANIFEST" ]; then
    ko "T5 : manifeste absent, exclusions D-31-03 non vérifiables"
  elif "$GREP" -qE '^(scripts/vf-portable\.sh|scripts/\.vibeflow-installed|scripts/\.vibeflow-manifest-)' "$MANIFEST"; then
    ko "T5 : le manifeste contient une entrée de la liste close d'exclusions D-31-03"
  else
    ok "T5 : aucune entrée de la liste close d'exclusions D-31-03 dans le manifeste"
  fi

  # T6 (31-03) — EXHAUSTIVITÉ : l'ensemble des lignes du manifeste est EXACTEMENT l'ensemble
  # des fichiers réellement créés sous $LAB/.claude, moins la liste close d'exclusions. Ce
  # fixture (software-architecture : SKILL.md + rules/ + references/ + scripts/ + scripts/tests/
  # + hooks/hooks.json) exerce plusieurs des ~35 sites migrés en tâche 2 — un site oublié à la
  # migration fait apparaître un chemin sur disque absent du manifeste, donc rougir T6.
  # settings*.json sort de l'ensemble comparé : ce sont des fichiers MERGÉS (verbe ~), pas des
  # poses de module — frontière déjà posée par D-31-03 (« les entrées de settings.json ne sont
  # pas des chemins », ARCHITECTURE.md §3.1), pas une exception négociée ici. Comparaison par
  # `comm` (jamais `diff` — outillage mesuré menteur sur ce poste, cf. 31-03-PLAN.md).
  T6_MANI_SORTED="$(mktemp)"
  T6_DISK_SORTED="$(mktemp)"
  LC_ALL=C sort "$MANIFEST" > "$T6_MANI_SORTED" 2>/dev/null || : > "$T6_MANI_SORTED"
  find "$LAB/.claude" -type f | sed "s#^$LAB/\.claude/##" \
    | "$GREP" -vE '^scripts/vf-portable\.sh$|^scripts/\.vibeflow-installed$|^scripts/\.vibeflow-manifest-|^settings\.json$|^settings\.local\.json$|^memory/|^\.backups/' \
    | LC_ALL=C sort > "$T6_DISK_SORTED"
  T6_MISSING="$(comm -23 "$T6_DISK_SORTED" "$T6_MANI_SORTED")"
  T6_EXTRA="$(comm -13 "$T6_DISK_SORTED" "$T6_MANI_SORTED")"
  if [ -z "$T6_MISSING" ] && [ -z "$T6_EXTRA" ]; then
    ok "T6 : manifeste == disque (moins exclusions), égalité d'ensembles totale"
  else
    ko "T6 : manifeste != disque — manquants du manifeste=[$(printf '%s' "$T6_MISSING" | tr '\n' ',')] en trop=[$(printf '%s' "$T6_EXTRA" | tr '\n' ',')]"
  fi
  rm -f "$T6_MANI_SORTED" "$T6_DISK_SORTED"

  # T6b (M3, revue 31-03) — existence POSITIVE du fichier injecté par le fixture .txt (site #3,
  # copy_module_scripts). T6 seul est AVEUGLE à ce site : si le site #3 est cassé, le fichier
  # n'atterrit NI sur disque NI au manifeste — les deux côtés restent d'accord (rien à comparer),
  # T6 reste vert par construction. T6b vérifie l'existence sur DISQUE ET la ligne EXACTE au
  # manifeste, indépendamment de T6. Discriminance prouvée par mutation (revue 31-03, cf. rapport) :
  # glob de la boucle `scripts/*.txt` neutré → T6 reste vert, T6b rougit.
  DISK_TXT="$LAB/.claude/scripts/known-versions.txt"
  if [ -f "$DISK_TXT" ] && [ -f "$MANIFEST" ] && awk '$0=="scripts/known-versions.txt"{f=1} END{exit !f}' "$MANIFEST"; then
    ok "T6b : M3 — scripts/known-versions.txt (site #3, fixture .txt) posé sur disque ET consigné au manifeste"
  else
    ko "T6b : M3 — scripts/known-versions.txt absent du disque et/ou du manifeste (site #3 cassé)"
  fi

  # T9 (31-03) — même liste close d'exclusions D-31-03 que T5, sur ce fixture plus riche (même
  # manifeste que T6). Cas distinct de T5 (fixture historique 31-01) : la couverture ne dépend
  # plus d'un seul site câblé.
  if [ ! -f "$MANIFEST" ]; then
    ko "T9 : manifeste absent, exclusions D-31-03 non vérifiables"
  elif "$GREP" -qE '^(scripts/vf-portable\.sh|scripts/\.vibeflow-installed|scripts/\.vibeflow-manifest-)' "$MANIFEST"; then
    ko "T9 : le manifeste contient une entrée de la liste close d'exclusions D-31-03"
  else
    ok "T9 : aucune entrée de la liste close d'exclusions D-31-03 dans le manifeste (fixture 31-03)"
  fi
else
  skip "T1-T5 : software-architecture non copiable dans le cache de test"
  skip "T6 : software-architecture non copiable dans le cache de test"
  skip "T6b : software-architecture non copiable dans le cache de test"
  skip "T9 : software-architecture non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T3b : scope `user` — TARGET_ROOT absolu ($HOME/.claude). Seul scope où une régression de
# relativisation (vf_rel_to_target cassée) peut réellement produire une ligne absolue dans le
# manifeste ; T3 seul (scope project, TARGET_ROOT="./.claude" déjà relatif) ne peut pas rougir.
# HOME isolé (fakehome) : une seule résolution de HOME à l'exécution (vérifié en revue) suffit.
# ---------------------------------------------------------------------------
LAB_USER="$(mktemp -d)"
FAKEHOME="$LAB_USER/fakehome"
CACHE_USER="$LAB_USER/cache"
mkdir -p "$FAKEHOME"
if prepare_module "$CACHE_USER" "software-architecture"; then
  (cd "$LAB_USER" && HOME="$FAKEHOME" VIBEFLOW_CACHE="$CACHE_USER" bash "$INSTALLER" --scope user install software-architecture >/dev/null 2>&1)
  MANIFEST_USER="$FAKEHOME/.claude/scripts/.vibeflow-manifest-software-architecture"
  if [ ! -f "$MANIFEST_USER" ]; then
    ko "T3b : manifeste absent (scope user), chemin absolu non vérifiable ($MANIFEST_USER)"
  elif "$GREP" -qE '^/' "$MANIFEST_USER"; then
    ko "T3b : au moins une ligne du manifeste (scope user) commence par une barre oblique (chemin absolu)"
  else
    ok "T3b : aucune ligne du manifeste (scope user, TARGET_ROOT absolu) ne commence par une barre oblique"
  fi
else
  skip "T3b : software-architecture non copiable dans le cache de test (scope user)"
fi
rm -rf "$LAB_USER"

# ---------------------------------------------------------------------------
# T4b : tri/dédup au grain UNITÉ (D-31-12) — source les fonctions et les appelle directement,
# sans attendre qu'un site de pose multi-fichiers (31-03) rende l'assertion de bout en bout
# significative. Sous-shell isolé : voir note de convention en tête de fichier.
# ---------------------------------------------------------------------------
T4B_LAB="$(mktemp -d)"
T4B_RESULT="$(
  cd "$T4B_LAB" 2>/dev/null || exit 1
  set -- sync
  # shellcheck disable=SC1090
  source "$INSTALLER" >/dev/null 2>&1
  vf_manifest_reset "unit-mod"
  vf_record "$TARGET_ROOT/skills/zzz/SKILL.md"
  vf_record "$TARGET_ROOT/skills/aaa/SKILL.md"
  vf_record "$TARGET_ROOT/skills/mmm/SKILL.md"
  vf_record "$TARGET_ROOT/skills/aaa/SKILL.md"   # doublon volontaire
  vf_manifest_flush
  manifest_t4b="$(vf_manifest_path "unit-mod")"
  expected="skills/aaa/SKILL.md
skills/mmm/SKILL.md
skills/zzz/SKILL.md"
  if [ -f "$manifest_t4b" ] && [ "$(cat "$manifest_t4b")" = "$expected" ]; then
    echo "PASS"
  else
    echo "FAIL:$(cat "$manifest_t4b" 2>/dev/null | tr '\n' '|')"
  fi
)"
rm -rf "$T4B_LAB"
case "$T4B_RESULT" in
  PASS) ok "T4b : vf_record/vf_manifest_flush trient LC_ALL=C et dédupliquent au grain unité" ;;
  *) ko "T4b : ordre/dédup incorrect au grain unité ($T4B_RESULT)" ;;
esac

# ---------------------------------------------------------------------------
# T5b : liste close D-31-03 au grain UNITÉ (D-31-12) — vf_manifest_excluded appelée directement
# sur les 5 motifs (doivent matcher) ET sur des chemins voisins (garde anti-sur-blocage, ne
# doivent PAS matcher). Aujourd'hui aucun chemin posé par le seul site câblé (SKILL.md racine)
# n'atteint cette liste : T5 seul est vacant (mutation `return 1` restée verte en revue).
# ---------------------------------------------------------------------------
T5B_LAB="$(mktemp -d)"
T5B_RESULT="$(
  cd "$T5B_LAB" 2>/dev/null || exit 1
  set -- sync
  # shellcheck disable=SC1090
  source "$INSTALLER" >/dev/null 2>&1
  fail_list=""
  check_excluded() {
    local path="$1" want="$2" got
    if vf_manifest_excluded "$path"; then got=0; else got=1; fi
    [ "$got" = "$want" ] || fail_list="$fail_list|$path(want=$want,got=$got)"
  }
  # Les 5 motifs D-31-03 : DOIVENT matcher (want=0, exclus du manifeste).
  check_excluded "scripts/vf-portable.sh" 0
  check_excluded "memory/foo.md" 0
  check_excluded "scripts/.vibeflow-installed" 0
  check_excluded "scripts/.vibeflow-manifest-conductor" 0
  check_excluded ".backups/conductor-20260101/skills/x" 0
  # Chemins voisins : ne doivent PAS matcher (want=1, anti-sur-blocage).
  check_excluded "scripts/vf-portable2.sh" 1
  check_excluded "skills/memory/SKILL.md" 1
  check_excluded "scripts/.vibeflow-installedx" 1
  check_excluded "scripts/vibeflow-manifest-conductor" 1
  check_excluded "notbackups/conductor/x" 1
  if [ -z "$fail_list" ]; then
    echo "PASS"
  else
    echo "FAIL:$fail_list"
  fi
)"
rm -rf "$T5B_LAB"
case "$T5B_RESULT" in
  PASS) ok "T5b : vf_manifest_excluded matche les 5 motifs D-31-03 et épargne les chemins voisins" ;;
  *) ko "T5b : $T5B_RESULT" ;;
esac

# ---------------------------------------------------------------------------
# T7 : grain fichier sur un cp -r (D-31-02) — module skill-creator (skills imbriqués, cp -r).
# Chaque fichier posé sous skills/skill-creator/... et skills/skill-creator-workflow/... doit
# apparaître comme une ligne de FICHIER dans le manifeste, jamais une ligne de répertoire.
# ---------------------------------------------------------------------------
LAB7="$(mktemp -d)"
CACHE7="$LAB7/cache"
if prepare_module "$CACHE7" "skill-creator"; then
  (cd "$LAB7" && VIBEFLOW_CACHE="$CACHE7" bash "$INSTALLER" install skill-creator >/dev/null 2>&1)
  MANIFEST7="$LAB7/.claude/scripts/.vibeflow-manifest-skill-creator"
  if [ -f "$MANIFEST7" ] \
     && awk '$0=="skills/skill-creator/SKILL.md"{f=1} END{exit !f}' "$MANIFEST7" \
     && ! "$GREP" -qE '/$' "$MANIFEST7"; then
    ok "T7 : cp -r (skills imbriqués) consigné au grain fichier, aucune ligne répertoire"
  else
    ko "T7 : grain fichier non respecté pour skill-creator ($MANIFEST7)"
  fi
else
  skip "T7 : skill-creator non copiable dans le cache de test"
fi
rm -rf "$LAB7"

# ---------------------------------------------------------------------------
# T7b : gel des dotfiles de premier niveau (D-31-11 point 2) — un fichier caché injecté à la
# racine d'un skill_dir copié par cp -r n'apparaît NI sur disque NI dans le manifeste. Comportement
# figé (pas corrigé) : remontée §7 n°4 du cadrage.
# ---------------------------------------------------------------------------
LAB7B="$(mktemp -d)"
CACHE7B="$LAB7B/cache"
if prepare_module "$CACHE7B" "skill-creator"; then
  printf 'marker\n' > "$CACHE7B/skill-creator/skills/skill-creator/.hidden-marker"
  (cd "$LAB7B" && VIBEFLOW_CACHE="$CACHE7B" bash "$INSTALLER" install skill-creator >/dev/null 2>&1)
  MANIFEST7B="$LAB7B/.claude/scripts/.vibeflow-manifest-skill-creator"
  DISK_HIDDEN7B="$LAB7B/.claude/skills/skill-creator/.hidden-marker"
  if [ ! -e "$DISK_HIDDEN7B" ] && { [ ! -f "$MANIFEST7B" ] || ! "$GREP" -qF ".hidden-marker" "$MANIFEST7B"; }; then
    ok "T7b : dotfile de premier niveau du src_dir ni posé ni consigné (comportement gelé)"
  else
    ko "T7b : dotfile de premier niveau posé et/ou consigné à tort (disque présent=$([ -e "$DISK_HIDDEN7B" ] && echo oui || echo non))"
  fi
else
  skip "T7b : skill-creator non copiable dans le cache de test"
fi
rm -rf "$LAB7B"

# ---------------------------------------------------------------------------
# T8 : asymétrie docs/ (D-31-03) — module doc pur `reference` (content/ seul). docs/reference/…
# est posé sur disque, mais AUCUNE ligne docs/ n'entre dans le manifeste. Moitié « présent au
# plan --dry-run » testable seulement à partir de 31-04 (--dry-run n'existe pas encore ici).
# ---------------------------------------------------------------------------
LAB8="$(mktemp -d)"
CACHE8="$LAB8/cache"
if prepare_module "$CACHE8" "reference"; then
  (cd "$LAB8" && VIBEFLOW_CACHE="$CACHE8" bash "$INSTALLER" install reference >/dev/null 2>&1)
  MANIFEST8="$LAB8/.claude/scripts/.vibeflow-manifest-reference"
  DOCS8_COUNT="$(find "$LAB8/docs/reference" -type f 2>/dev/null | awk 'END{print NR}')"
  MANI8_HAS_DOCS=0
  [ -f "$MANIFEST8" ] && "$GREP" -qE '^docs/' "$MANIFEST8" && MANI8_HAS_DOCS=1
  if [ "${DOCS8_COUNT:-0}" -gt 0 ] && [ "$MANI8_HAS_DOCS" -eq 0 ]; then
    ok "T8 : docs/reference posé sur disque ($DOCS8_COUNT fichier(s)), AUCUNE ligne docs/ au manifeste"
  else
    ko "T8 : asymétrie docs/ non respectée (docs sur disque=${DOCS8_COUNT:-0}, manifeste a des lignes docs/=$MANI8_HAS_DOCS)"
  fi
else
  skip "T8 : reference non copiable dans le cache de test"
fi
rm -rf "$LAB8"

# ---------------------------------------------------------------------------
# T9b : copie dégradée journalisée, non fatale (D-31-11 point 4) — collision fichier/répertoire
# forcée sur UNE seule entrée d'un cp -r (skill-creator). Après install (qui NE DOIT PAS sortir en
# échec) : (a) message de divergence sur stderr avec le chemin en collision ; (b) chemin ABSENT
# du manifeste ; (c) les AUTRES fichiers du même répertoire source restent présents en manifeste.
# ---------------------------------------------------------------------------
LAB9B="$(mktemp -d)"
CACHE9B="$LAB9B/cache"
if prepare_module "$CACHE9B" "skill-creator"; then
  mkdir -p "$LAB9B/.claude/skills/skill-creator/SKILL.md"   # collision : dest pré-créée en RÉPERTOIRE
  OUT9B="$(mktemp)"
  (cd "$LAB9B" && VIBEFLOW_CACHE="$CACHE9B" bash "$INSTALLER" install skill-creator) >"$OUT9B" 2>&1
  RC9B=$?
  MANIFEST9B="$LAB9B/.claude/scripts/.vibeflow-manifest-skill-creator"
  if [ "$RC9B" -eq 0 ] \
     && "$GREP" -qE 'copie dégradée : .*skill-creator/SKILL\.md$' "$OUT9B" \
     && [ -f "$MANIFEST9B" ] \
     && ! "$GREP" -qxF "skills/skill-creator/SKILL.md" "$MANIFEST9B" \
     && "$GREP" -qxF "skills/skill-creator/LICENSE.txt" "$MANIFEST9B"; then
    ok "T9b : copie dégradée journalisée (chemin nommé), absente du manifeste, reste de la pose intact (rc=0)"
  else
    ko "T9b : copie dégradée non conforme (rc=$RC9B) — voir $OUT9B"
  fi
  rm -f "$OUT9B"
else
  skip "T9b : skill-creator non copiable dans le cache de test"
fi
rm -rf "$LAB9B"

# ---------------------------------------------------------------------------
# T9c : trou de silence rattrapé (D-31-11 point 4 §Complément, W-2) — un skill_dir source RENDU
# ENTIÈREMENT ILLISIBLE (chmod 000, restauré avant tout retour du cas) fait échouer le cp -r
# intégralement ; l'énumération rend zéro paire, la boucle de vérification n'a rien à signaler.
# Sans le garde du trou de silence, ce cas serait totalement silencieux. Après install (qui NE DOIT
# PAS sortir en échec) : une ligne de compte rendu apparaît malgré tout sur stderr.
# ---------------------------------------------------------------------------
LAB9C="$(mktemp -d)"
CACHE9C="$LAB9C/cache"
if prepare_module "$CACHE9C" "skill-creator"; then
  SRC9C="$CACHE9C/skill-creator/skills/skill-creator"
  chmod 000 "$SRC9C"
  OUT9C="$(mktemp)"
  (cd "$LAB9C" && VIBEFLOW_CACHE="$CACHE9C" bash "$INSTALLER" install skill-creator) >"$OUT9C" 2>&1
  RC9C=$?
  chmod 755 "$SRC9C"   # restauré AVANT tout retour du cas, y compris un échec d'assertion
  if [ "$RC9C" -eq 0 ] \
     && "$GREP" -qE 'copie dégradée : .*skill-creator/skills/skill-creator .*source illisible' "$OUT9C"; then
    ok "T9c : source illisible → ligne de compte rendu émise malgré tout (trou de silence rattrapé), install non avortée (rc=0)"
  else
    ko "T9c : trou de silence NON rattrapé (rc=$RC9C) — voir $OUT9C"
  fi
  rm -f "$OUT9C"
else
  chmod 755 "$SRC9C" 2>/dev/null || true
  skip "T9c : skill-creator non copiable dans le cache de test"
fi
rm -rf "$LAB9C"

# ---------------------------------------------------------------------------
# T10-T13 (B1-B4, revue 31-03, D-31-13) — injection de panne RÉELLE (chmod 000) sur les quatre
# sites où la migration 31-03 avait réduit une chaîne tolérante (`cp` médian + `&&`, ou `|| true`)
# à un appel nu de helper en POSITION FINALE de boucle : avant correctif, l'échec d'UN SEUL fichier
# illisible avortait `install` entier (rc=1, message `cp:`/`find:` brut). Chaque cas ci-dessous
# assure rc=0 (install non avortée) ET la présence d'une trace « copie dégradée » — ce qui aurait
# rougi tel quel sur l'engine tel que commité en 263c177 (vérifié manuellement en revue, cf.
# rapport de la correction ciblée : rc=1 sur les 4 sites avant, rc=0 après).
# ---------------------------------------------------------------------------

# T10 (B1) : vf_place_tree — sous-répertoire NICHÉ illisible dans un cp -r (skill-creator/skills/
# skill-creator/references), au-delà du grain « skill_dir entier » déjà couvert par T9c.
LAB10="$(mktemp -d)"
CACHE10="$LAB10/cache"
if prepare_module "$CACHE10" "skill-creator"; then
  SRC10="$CACHE10/skill-creator/skills/skill-creator/references"
  if [ -d "$SRC10" ]; then
    chmod 000 "$SRC10"
    OUT10="$(mktemp)"
    (cd "$LAB10" && VIBEFLOW_CACHE="$CACHE10" bash "$INSTALLER" install skill-creator) >"$OUT10" 2>&1
    RC10=$?
    chmod 755 "$SRC10"   # restauré AVANT tout retour du cas
    if [ "$RC10" -eq 0 ] && "$GREP" -qE 'copie dégradée : .*references.*(illisible|échec)' "$OUT10"; then
      ok "T10 : B1 — sous-répertoire niché illisible (vf_place_tree), install non avortée (rc=0), tracée"
    else
      ko "T10 : B1 non corrigé (rc=$RC10) — voir $OUT10"
    fi
    rm -f "$OUT10"
  else
    skip "T10 : skills/skill-creator/references absent du fixture"
  fi
else
  chmod 755 "$SRC10" 2>/dev/null || true
  skip "T10 : skill-creator non copiable dans le cache de test"
fi
rm -rf "$LAB10"

# T11 (B2) : install_module — rules/*.md illisible (avant : `cp … 2>/dev/null || true`).
LAB11="$(mktemp -d)"
CACHE11="$LAB11/cache"
if prepare_module "$CACHE11" "software-architecture"; then
  SRC11="$CACHE11/software-architecture/rules/production-code-architecture.md"
  chmod 000 "$SRC11"
  OUT11="$(mktemp)"
  (cd "$LAB11" && VIBEFLOW_CACHE="$CACHE11" bash "$INSTALLER" install software-architecture) >"$OUT11" 2>&1
  RC11=$?
  chmod 644 "$SRC11"
  if [ "$RC11" -eq 0 ] && "$GREP" -qE 'copie dégradée : .*production-code-architecture\.md' "$OUT11"; then
    ok "T11 : B2 — rules/*.md illisible, install non avortée (rc=0), tracée"
  else
    ko "T11 : B2 non corrigé (rc=$RC11) — voir $OUT11"
  fi
  rm -f "$OUT11"
else
  chmod 644 "$SRC11" 2>/dev/null || true
  skip "T11 : software-architecture non copiable dans le cache de test"
fi
rm -rf "$LAB11"

# T12 (B3) : copy_module_scripts — scripts/tests/*.sh illisible (avant : `|| true` indépendant).
LAB12="$(mktemp -d)"
CACHE12="$LAB12/cache"
if prepare_module "$CACHE12" "software-architecture"; then
  SRC12="$CACHE12/software-architecture/scripts/tests/test-check-file-size.sh"
  chmod 000 "$SRC12"
  OUT12="$(mktemp)"
  (cd "$LAB12" && VIBEFLOW_CACHE="$CACHE12" bash "$INSTALLER" install software-architecture) >"$OUT12" 2>&1
  RC12=$?
  chmod 755 "$SRC12"
  if [ "$RC12" -eq 0 ] && "$GREP" -qE 'copie dégradée : .*test-check-file-size\.sh' "$OUT12"; then
    ok "T12 : B3 — scripts/tests/*.sh illisible, install non avortée (rc=0), tracée"
  else
    ko "T12 : B3 non corrigé (rc=$RC12) — voir $OUT12"
  fi
  rm -f "$OUT12"
else
  chmod 755 "$SRC12" 2>/dev/null || true
  skip "T12 : software-architecture non copiable dans le cache de test"
fi
rm -rf "$LAB12"

# T13 (B4) : copy_module_scripts — scripts/*.sh illisible (avant : `[ -f ] && cp && chmod +x`,
# cp médian exempté).
LAB13="$(mktemp -d)"
CACHE13="$LAB13/cache"
if prepare_module "$CACHE13" "software-architecture"; then
  SRC13="$CACHE13/software-architecture/scripts/check-file-size.sh"
  chmod 000 "$SRC13"
  OUT13="$(mktemp)"
  (cd "$LAB13" && VIBEFLOW_CACHE="$CACHE13" bash "$INSTALLER" install software-architecture) >"$OUT13" 2>&1
  RC13=$?
  chmod 755 "$SRC13"
  if [ "$RC13" -eq 0 ] && "$GREP" -qE 'copie dégradée : .*check-file-size\.sh' "$OUT13"; then
    ok "T13 : B4 — scripts/*.sh illisible, install non avortée (rc=0), tracée"
  else
    ko "T13 : B4 non corrigé (rc=$RC13) — voir $OUT13"
  fi
  rm -f "$OUT13"
else
  chmod 755 "$SRC13" 2>/dev/null || true
  skip "T13 : software-architecture non copiable dans le cache de test"
fi
rm -rf "$LAB13"

# ---------------------------------------------------------------------------
# T14/T14b (M2, revue 31-03) — `vf_place_tree` ne crie plus À TORT sur un `$src_dir` légitimement
# VIDE mais LISIBLE (`cp_rc` seul était un faux positif, même couple de symptômes qu'un répertoire
# illisible). T14b est la contre-épreuve : un répertoire RÉELLEMENT illisible continue de crier —
# le garde ne doit pas avoir supprimé le signal légitime. Unité : source les fonctions (même
# convention que T4b/T5b).
# ---------------------------------------------------------------------------
T14_LAB="$(mktemp -d)"
T14_RESULT="$(
  cd "$T14_LAB" 2>/dev/null || exit 1
  set -- sync
  # shellcheck disable=SC1090
  source "$INSTALLER" >/dev/null 2>&1
  mkdir -p empty_src dest
  vf_place_tree "$PWD/empty_src" "$PWD/dest" >/dev/null 2>&1
  echo "$VF_DEGRADED_COPIES_COUNT"
)"
rm -rf "$T14_LAB"
if [ "$T14_RESULT" = "0" ]; then
  ok "T14 : M2 — répertoire source vide mais lisible, aucun cri de copie dégradée (faux positif corrigé)"
else
  ko "T14 : M2 — faux positif persistant sur répertoire vide lisible (VF_DEGRADED_COPIES_COUNT=$T14_RESULT, attendu 0)"
fi

T14B_LAB="$(mktemp -d)"
mkdir -p "$T14B_LAB/unreadable_src/sub" "$T14B_LAB/dest2"
printf 'x\n' > "$T14B_LAB/unreadable_src/sub/f.txt"
chmod 000 "$T14B_LAB/unreadable_src"
T14B_RESULT="$(
  cd "$T14B_LAB" 2>/dev/null || exit 1
  set -- sync
  # shellcheck disable=SC1090
  source "$INSTALLER" >/dev/null 2>&1
  vf_place_tree "$T14B_LAB/unreadable_src" "$T14B_LAB/dest2" >/dev/null 2>&1
  echo "$VF_DEGRADED_COPIES_COUNT"
)"
chmod 755 "$T14B_LAB/unreadable_src"
rm -rf "$T14B_LAB"
if [ -n "$T14B_RESULT" ] && [ "$T14B_RESULT" -gt 0 ] 2>/dev/null; then
  ok "T14b : M2 contre-épreuve — répertoire source réellement illisible crie toujours (VF_DEGRADED_COPIES_COUNT=$T14B_RESULT)"
else
  ko "T14b : M2 contre-épreuve — signal légitime perdu (VF_DEGRADED_COPIES_COUNT=${T14B_RESULT:-<vide>})"
fi

# ---------------------------------------------------------------------------
# T15 (M6, revue 31-03) — `uninstall` retire le manifeste .vibeflow-manifest-<mod> : sans ce
# retrait, il survit à la désinstallation et devient un module FANTÔME pour la découverte par
# glob (.vibeflow-manifest-*) annoncée en 31-05/31-07.
# ---------------------------------------------------------------------------
LAB15="$(mktemp -d)"
CACHE15="$LAB15/cache"
if prepare_module "$CACHE15" "software-architecture"; then
  (cd "$LAB15" && VIBEFLOW_CACHE="$CACHE15" bash "$INSTALLER" install software-architecture >/dev/null 2>&1)
  MANIFEST15="$LAB15/.claude/scripts/.vibeflow-manifest-software-architecture"
  if [ -f "$MANIFEST15" ]; then
    (cd "$LAB15" && VIBEFLOW_CACHE="$CACHE15" bash "$INSTALLER" uninstall software-architecture >/dev/null 2>&1)
    if [ ! -f "$MANIFEST15" ]; then
      ok "T15 : M6 — manifeste retiré à la désinstallation (aucun module fantôme)"
    else
      ko "T15 : M6 — manifeste survit à uninstall ($MANIFEST15 toujours présent)"
    fi
  else
    ko "T15 : M6 — manifeste jamais créé à l'install, cas non vérifiable"
  fi
else
  skip "T15 : software-architecture non copiable dans le cache de test"
fi
rm -rf "$LAB15"

# ---------------------------------------------------------------------------
# T16 (M5, revue 31-03) — settings.json/settings.local.json sont désormais dans le POINT UNIQUE
# de définition (vf_manifest_excluded, D-31-03), pas neutralisés par un second filtre privé sous
# T6 (le doublon que D-31-03 interdit explicitement). Grain unité, même convention que T5b.
# ---------------------------------------------------------------------------
T16_LAB="$(mktemp -d)"
T16_RESULT="$(
  cd "$T16_LAB" 2>/dev/null || exit 1
  set -- sync
  # shellcheck disable=SC1090
  source "$INSTALLER" >/dev/null 2>&1
  fail_list=""
  check_excluded() {
    local path="$1" want="$2" got
    if vf_manifest_excluded "$path"; then got=0; else got=1; fi
    [ "$got" = "$want" ] || fail_list="$fail_list|$path(want=$want,got=$got)"
  }
  check_excluded "settings.json" 0
  check_excluded "settings.local.json" 0
  check_excluded "skills/settings.json/SKILL.md" 1
  if [ -z "$fail_list" ]; then
    echo "PASS"
  else
    echo "FAIL:$fail_list"
  fi
)"
rm -rf "$T16_LAB"
case "$T16_RESULT" in
  PASS) ok "T16 : M5 — settings.json/settings.local.json dans le point UNIQUE vf_manifest_excluded" ;;
  *) ko "T16 : M5 — $T16_RESULT" ;;
esac

# ===========================================================================
# TD1-TD8 (31-04, MANI-02, D-31-04) — preuves du flag --dry-run. Nommage TD<n>, voir en-tête.
# ===========================================================================

# ---------------------------------------------------------------------------
# TD1 (= T10 du plan) — ÉGALITÉ TOTALE : sur software-architecture (fixture SANS aucun
# sous-processus de régime C), l'ensemble des chemins annoncés par --dry-run install est
# EXACTEMENT l'ensemble des chemins créés/modifiés par le MÊME install réel dans un lab jumeau.
# Aucune liste d'exceptions négociée (D-31-04) — comparaison par `comm`, jamais `diff` ni un
# filtre d'exclusion négatif (outillage proxifié mesuré menteur sur ce poste). Trois mktemp -d
# DISJOINTS : le cache n'est JAMAIS sous un lab, sinon `find` le ramasse et l'égalité devient
# impossible.
# ---------------------------------------------------------------------------
LAB_TD1_PLAN="$(mktemp -d)"
LAB_TD1_REEL="$(mktemp -d)"
CACHE_TD1="$(mktemp -d)"
if prepare_module "$CACHE_TD1" "software-architecture"; then
  TD1_PLAN_OUT="$(mktemp)"
  (cd "$LAB_TD1_PLAN" && VIBEFLOW_CACHE="$CACHE_TD1" bash "$INSTALLER" --dry-run install software-architecture) >"$TD1_PLAN_OUT" 2>/dev/null
  (cd "$LAB_TD1_REEL" && VIBEFLOW_CACHE="$CACHE_TD1" bash "$INSTALLER" install software-architecture) >/dev/null 2>&1

  # Déterminisme rendu EXPLICITE plutôt qu'espéré : sur une install FRAÎCHE dans un lab vierge,
  # ni le backup de settings ni backup_module ne se déclenchent (aucune des deux conditions n'est
  # vraie) — donc AUCUN chemin horodaté ne doit exister. Si cette assertion tombe un jour, le test
  # rougit en nommant la vraie cause au lieu de flaker sur une comparaison de chaînes.
  if [ -d "$LAB_TD1_REEL/.claude/.backups" ]; then
    ko "TD1 : .claude/.backups existe après une install FRAÎCHE — préconditions de déterminisme fausses, égalité non fiable"
  else
    TD1_PLAN_SORTED="$(mktemp)"
    TD1_REEL_SORTED="$(mktemp)"
    awk '/^\[plan\] /{print $3}' "$TD1_PLAN_OUT" | LC_ALL=C sort > "$TD1_PLAN_SORTED"
    (cd "$LAB_TD1_REEL" && find . -type f) | LC_ALL=C sort > "$TD1_REEL_SORTED"
    TD1_MISSING="$(comm -23 "$TD1_REEL_SORTED" "$TD1_PLAN_SORTED")"
    TD1_EXTRA="$(comm -13 "$TD1_REEL_SORTED" "$TD1_PLAN_SORTED")"
    if [ -z "$TD1_MISSING" ] && [ -z "$TD1_EXTRA" ]; then
      ok "TD1 : MANI-02 — dry-run == pose réelle, égalité d'ensembles TOTALE (software-architecture, aucune exception)"
    else
      ko "TD1 : dry-run != pose réelle — manquants-au-plan=[$(printf '%s' "$TD1_MISSING" | tr '\n' ',')] en-trop-au-plan=[$(printf '%s' "$TD1_EXTRA" | tr '\n' ',')]"
    fi
    rm -f "$TD1_PLAN_SORTED" "$TD1_REEL_SORTED"
  fi
  rm -f "$TD1_PLAN_OUT"
else
  skip "TD1 : software-architecture non copiable dans le cache de test"
fi
rm -rf "$LAB_TD1_PLAN" "$LAB_TD1_REEL" "$CACHE_TD1"

# ---------------------------------------------------------------------------
# TD2 (= T10b du plan) — RÉGIME A, discriminance : dev-orchestrator (AGENT.md +
# scripts/build-gsd-index.sh + scripts/build-gsd-capabilities-index.sh, mesuré sur pièce) —
# --dry-run install annonce les 3 lignes régime A malgré l'ABSENCE de toute destination sur
# disque (lab vierge) — preuve du piège de garde côté SOURCE (D-31-04). Pas d'égalité totale
# exigée ici (dev-orchestrator déclenche aussi inject-mcp-tools.sh, régime C) : assertion de
# PRÉSENCE, la prétention distincte que TD4 porte déjà pour un autre régime.
# ---------------------------------------------------------------------------
LAB_TD2="$(mktemp -d)"
CACHE_TD2="$(mktemp -d)"
if prepare_module "$CACHE_TD2" "dev-orchestrator"; then
  TD2_OUT="$(cd "$LAB_TD2" && VIBEFLOW_CACHE="$CACHE_TD2" bash "$INSTALLER" --dry-run install dev-orchestrator 2>/dev/null)"
  if printf '%s\n' "$TD2_OUT" | "$GREP" -qE '^\[plan\] \+ .*/commands/dev-orchestrator\.md' \
     && printf '%s\n' "$TD2_OUT" | "$GREP" -qE '^\[plan\] \+ .*/gsd-skills-index\.md' \
     && printf '%s\n' "$TD2_OUT" | "$GREP" -qE '^\[plan\] \+ .*/gsd-capabilities-index\.md'; then
    ok "TD2 : régime A — 3 lignes annoncées (commande d'incarnation + 2 index) malgré destination absente (lab vierge, dev-orchestrator)"
  else
    ko "TD2 : au moins une ligne régime A absente du plan (dev-orchestrator, lab vierge) — sortie : $(printf '%s' "$TD2_OUT" | tr '\n' '|')"
  fi
else
  skip "TD2 : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB_TD2" "$CACHE_TD2"

# ---------------------------------------------------------------------------
# TD3 (= T11 du plan) — ARBRE INCHANGÉ : empreinte `find` du lab ENTIER (pas seulement .claude —
# couvre aussi ./.gitignore et docs/, D-31-11.3) identique avant/après --dry-run. Scope LOCAL :
# seul scope où gitignore_add_paths écrit réellement — c'est la version machine de « un dry-run
# n'écrit rien du tout » (D-31-06).
# ---------------------------------------------------------------------------
LAB_TD3="$(mktemp -d)"
CACHE_TD3="$(mktemp -d)"
if prepare_module "$CACHE_TD3" "software-architecture"; then
  TD3_BEFORE="$(cd "$LAB_TD3" && find . | LC_ALL=C sort)"
  (cd "$LAB_TD3" && VIBEFLOW_CACHE="$CACHE_TD3" bash "$INSTALLER" --scope local --dry-run install software-architecture >/dev/null 2>&1)
  TD3_AFTER="$(cd "$LAB_TD3" && find . | LC_ALL=C sort)"
  if [ "$TD3_BEFORE" = "$TD3_AFTER" ]; then
    ok "TD3 : D-31-06 — empreinte find du lab entier (scope local) identique avant/après --dry-run"
  else
    ko "TD3 : le lab a changé pendant un --dry-run — before=[$(printf '%s' "$TD3_BEFORE" | tr '\n' ',')] after=[$(printf '%s' "$TD3_AFTER" | tr '\n' ',')]"
  fi
else
  skip "TD3 : software-architecture non copiable dans le cache de test"
fi
rm -rf "$LAB_TD3" "$CACHE_TD3"

# ---------------------------------------------------------------------------
# TD4 (= T12 du plan) — RÉGIME C, fixture qui le déclenche RÉELLEMENT : consolidator
# (scripts/seed-registres.sh) — --dry-run install annonce une ligne mentionnant seed-registres.sh
# et le marqueur de non-énumération. Assertion de PRÉSENCE, pas d'égalité (D-31-04).
# ---------------------------------------------------------------------------
LAB_TD4="$(mktemp -d)"
CACHE_TD4="$(mktemp -d)"
if prepare_module "$CACHE_TD4" "consolidator"; then
  TD4_OUT="$(cd "$LAB_TD4" && VIBEFLOW_CACHE="$CACHE_TD4" bash "$INSTALLER" --dry-run install consolidator 2>/dev/null)"
  if printf '%s\n' "$TD4_OUT" | "$GREP" -qE '^\[plan\] ~ .*memory.*effet de seed-registres\.sh.*contenu non énuméré'; then
    ok "TD4 : régime C — ligne d'annonce seed-registres.sh présente (consolidator, effet non énuméré)"
  else
    ko "TD4 : ligne d'annonce régime C absente (consolidator) — sortie : $(printf '%s' "$TD4_OUT" | tr '\n' '|')"
  fi
else
  skip "TD4 : consolidator non copiable dans le cache de test"
fi
rm -rf "$LAB_TD4" "$CACHE_TD4"

# ---------------------------------------------------------------------------
# TD5 (= T13 du plan) — exclusion D-31-03 côté MANIFESTE pour régime C : après un install RÉEL de
# consolidator, le manifeste ne contient AUCUNE ligne memory/ (contenu vivant du lab, exclu par
# construction). F-08 (correction ciblée 31-04) : ce test porte SEULE la moitié « absent du
# manifeste » — l'asymétrie plan/manifeste complète est TD4 (moitié « annoncé au plan ») + TD5
# ensemble, jamais TD5 seule (cf. légende corrigée en tête de fichier).
# ---------------------------------------------------------------------------
LAB_TD5="$(mktemp -d)"
CACHE_TD5="$(mktemp -d)"
if prepare_module "$CACHE_TD5" "consolidator"; then
  (cd "$LAB_TD5" && VIBEFLOW_CACHE="$CACHE_TD5" bash "$INSTALLER" install consolidator >/dev/null 2>&1)
  MANIFEST_TD5="$LAB_TD5/.claude/scripts/.vibeflow-manifest-consolidator"
  if [ -f "$MANIFEST_TD5" ] && ! "$GREP" -qE '^memory/' "$MANIFEST_TD5"; then
    ok "TD5 : D-31-03 — aucune ligne memory/ au manifeste après install réel de consolidator (moitié « absent du manifeste » de l'exclusion, PAS l'asymétrie complète — voir TD4)"
  else
    ko "TD5 : manifeste absent ou contient une ligne memory/ ($MANIFEST_TD5)"
  fi
else
  skip "TD5 : consolidator non copiable dans le cache de test"
fi
rm -rf "$LAB_TD5" "$CACHE_TD5"

# ---------------------------------------------------------------------------
# TD6 (= T13b du plan) — asymétrie docs/, MOITIÉ « présent au plan » (31-03/T8 ne prouvait que
# la moitié « absent du manifeste ») : module reference (content/ seul, docs/reference/ réel) —
# le --dry-run install annonce AU MOINS une ligne ^\[plan\] \+ .*docs/reference/.
# ---------------------------------------------------------------------------
LAB_TD6="$(mktemp -d)"
CACHE_TD6="$(mktemp -d)"
if prepare_module "$CACHE_TD6" "reference"; then
  TD6_OUT="$(cd "$LAB_TD6" && VIBEFLOW_CACHE="$CACHE_TD6" bash "$INSTALLER" --dry-run install reference 2>/dev/null)"
  if printf '%s\n' "$TD6_OUT" | "$GREP" -qE '^\[plan\] \+ .*docs/reference/'; then
    ok "TD6 : D-31-03 — docs/reference/ annoncé au plan (moitié « présent au plan » de l'asymétrie, ferme 31-03/T8)"
  else
    ko "TD6 : aucune ligne docs/reference/ au plan (reference) — sortie : $(printf '%s' "$TD6_OUT" | tr '\n' '|')"
  fi
else
  skip "TD6 : reference non copiable dans le cache de test"
fi
rm -rf "$LAB_TD6" "$CACHE_TD6"

# ---------------------------------------------------------------------------
# TD7 (= T13c du plan) — gel des dotfiles, MOITIÉ « absent du plan » (symétrique de 31-03/T7b,
# qui ne prouve que la moitié « absent du disque/manifeste » à la pose réelle) : fixture
# skill-creator + .hidden-marker injecté à la racine d'un skill_dir (MÊME injection que T7b) —
# le --dry-run install n'annonce AUCUNE ligne ^\[plan\] \+ .*\.hidden-marker.
# ---------------------------------------------------------------------------
LAB_TD7="$(mktemp -d)"
CACHE_TD7="$(mktemp -d)"
if prepare_module "$CACHE_TD7" "skill-creator"; then
  printf 'marker\n' > "$CACHE_TD7/skill-creator/skills/skill-creator/.hidden-marker"
  TD7_OUT="$(cd "$LAB_TD7" && VIBEFLOW_CACHE="$CACHE_TD7" bash "$INSTALLER" --dry-run install skill-creator 2>/dev/null)"
  if ! printf '%s\n' "$TD7_OUT" | "$GREP" -qE '^\[plan\] \+ .*\.hidden-marker'; then
    ok "TD7 : D-31-11.2 — dotfile de premier niveau JAMAIS annoncé au plan (gel tenu côté plan, symétrique de T7b)"
  else
    ko "TD7 : le dotfile de premier niveau est annoncé au plan à tort — sortie : $(printf '%s' "$TD7_OUT" | tr '\n' '|')"
  fi
else
  skip "TD7 : skill-creator non copiable dans le cache de test"
fi
rm -rf "$LAB_TD7" "$CACHE_TD7"

# ---------------------------------------------------------------------------
# TD8 (= T14 du plan) — refus bruyant : --dry-run uninstall <mod> sort 1 et n'a RIEN supprimé
# (D-31-06 — surface du flag bornée à install/update).
# ---------------------------------------------------------------------------
LAB_TD8="$(mktemp -d)"
CACHE_TD8="$(mktemp -d)"
if prepare_module "$CACHE_TD8" "software-architecture"; then
  (cd "$LAB_TD8" && VIBEFLOW_CACHE="$CACHE_TD8" bash "$INSTALLER" install software-architecture >/dev/null 2>&1)
  TD8_BEFORE="$(cd "$LAB_TD8" && find .claude -type f | LC_ALL=C sort)"
  TD8_ERR="$(mktemp)"
  (cd "$LAB_TD8" && VIBEFLOW_CACHE="$CACHE_TD8" bash "$INSTALLER" --dry-run uninstall software-architecture) >/dev/null 2>"$TD8_ERR"
  TD8_RC=$?
  TD8_AFTER="$(cd "$LAB_TD8" && find .claude -type f | LC_ALL=C sort)"
  if [ "$TD8_RC" -eq 1 ] && [ "$TD8_BEFORE" = "$TD8_AFTER" ] && "$GREP" -qE 'install' "$TD8_ERR" && "$GREP" -qE 'update' "$TD8_ERR"; then
    ok "TD8 : D-31-06 — --dry-run uninstall refusé (rc=1), rien supprimé, message nomme install et update"
  else
    ko "TD8 : refus non conforme (rc=$TD8_RC) — voir $TD8_ERR"
  fi
  rm -f "$TD8_ERR"
else
  skip "TD8 : software-architecture non copiable dans le cache de test"
fi
rm -rf "$LAB_TD8" "$CACHE_TD8"

# ===========================================================================
# TD9-TD13 — correction ciblée 31-04 (findings fusionnés revue + vérification --dry-run).
# ===========================================================================

# ---------------------------------------------------------------------------
# TD9 (F-01) — MULTI-MODULE : `install --all --dry-run` sur un cache à DEUX modules porteurs de
# hooks/hooks.json (consolidator, software-architecture — ordre alphabétique du for de
# list_available_modules) doit annoncer AUTANT de lignes `.backups/settings-…` que la pose RÉELLE
# en crée. Mesuré sur pièce AVANT correctif : pose réelle = 1 backup (consolidator crée
# settings.json, software-architecture le backupe), dry-run = 0 ligne annoncée — la garde
# `[ -f "$TARGET_ROOT/settings.json" ]` lit le disque, qui ne bouge jamais en dry-run, donc ne voit
# jamais l'effet du 1er module sur le 2e du MÊME run. TD1 (mono-module, software-architecture
# seul) ne peut PAS voir ce défaut : aucun module antérieur du run n'y crée settings.json.
# ---------------------------------------------------------------------------
LAB_TD9_PLAN="$(mktemp -d)"
LAB_TD9_REEL="$(mktemp -d)"
CACHE_TD9="$(mktemp -d)"
if prepare_module "$CACHE_TD9" "consolidator" && prepare_module "$CACHE_TD9" "software-architecture"; then
  (cd "$LAB_TD9_REEL" && VIBEFLOW_CACHE="$CACHE_TD9" bash "$INSTALLER" install --all >/dev/null 2>&1)
  TD9_REEL_BACKUPS="$(find "$LAB_TD9_REEL/.claude/.backups" -type f 2>/dev/null | wc -l | tr -d ' ')"
  TD9_PLAN_OUT="$(cd "$LAB_TD9_PLAN" && VIBEFLOW_CACHE="$CACHE_TD9" bash "$INSTALLER" --dry-run install --all 2>/dev/null)"
  TD9_PLAN_BACKUPS="$(printf '%s\n' "$TD9_PLAN_OUT" | "$GREP" -cE '^\[plan\] \+ .*\.backups/settings-')"
  if [ "$TD9_REEL_BACKUPS" -ge 1 ] && [ "$TD9_PLAN_BACKUPS" -eq "$TD9_REEL_BACKUPS" ]; then
    ok "TD9 : F-01 — install --all --dry-run annonce $TD9_PLAN_BACKUPS backup(s) settings.json, identique à la pose réelle ($TD9_REEL_BACKUPS)"
  else
    ko "TD9 : F-01 — plan=$TD9_PLAN_BACKUPS backup(s) annoncé(s), réel=$TD9_REEL_BACKUPS backup(s) créé(s) — divergence multi-module"
  fi
else
  skip "TD9 : consolidator ou software-architecture non copiable dans le cache de test"
fi
rm -rf "$LAB_TD9_PLAN" "$LAB_TD9_REEL" "$CACHE_TD9"

# ---------------------------------------------------------------------------
# TD10 (F-02) — `update --all --dry-run` sur un lab où AUCUN module n'a bougé de version (chemin le
# plus fréquent en usage réel, /vf-calibrate ou /vf-update sur un lab à jour) : chaque ligne
# `[plan] + …` doit porter un suffixe `(<module> <version>)` CORRECT, jamais `( —)`. Avant
# correctif : sync_module_governance n'ouvrait jamais VF_MANIFEST_MOD sur ce chemin, donc 100% des
# lignes tombaient à `( —)`, silencieusement (aucune erreur, juste un plan malformé — ADR-031).
# ---------------------------------------------------------------------------
LAB_TD10="$(mktemp -d)"
CACHE_TD10="$(mktemp -d)"
if prepare_module "$CACHE_TD10" "consolidator" && prepare_module "$CACHE_TD10" "software-architecture"; then
  (cd "$LAB_TD10" && VIBEFLOW_CACHE="$CACHE_TD10" bash "$INSTALLER" install --all >/dev/null 2>&1)
  TD10_OUT="$(cd "$LAB_TD10" && VIBEFLOW_CACHE="$CACHE_TD10" bash "$INSTALLER" --dry-run update --all 2>/dev/null)"
  TD10_PLUS="$(printf '%s\n' "$TD10_OUT" | "$GREP" -cE '^\[plan\] \+ ')"
  TD10_DASH="$(printf '%s\n' "$TD10_OUT" | "$GREP" -cE '\( —\)')"
  if [ "$TD10_PLUS" -gt 0 ] && [ "$TD10_DASH" -eq 0 ]; then
    ok "TD10 : F-02 — update --all --dry-run (version inchangée) : $TD10_PLUS ligne(s) +, 0 avec suffixe (—)"
  else
    ko "TD10 : F-02 — update --all --dry-run : $TD10_DASH ligne(s) sur $TD10_PLUS portent le suffixe (—) — module/version non résolu"
  fi
else
  skip "TD10 : consolidator ou software-architecture non copiable dans le cache de test"
fi
rm -rf "$LAB_TD10" "$CACHE_TD10"

# ---------------------------------------------------------------------------
# TD11 (F-04) — verbe de `.vibeflow-installed` sur lab VIERGE : la cible n'existe pas encore →
# verbe `+` (créer, D-31-05), jamais `~` (modifier) — une fausse déclaration de modification pour
# une création, sur le fichier qui EST le registre d'install, contredit le but même du dry-run
# (consentement éclairé, ADR-031).
# ---------------------------------------------------------------------------
LAB_TD11="$(mktemp -d)"
CACHE_TD11="$(mktemp -d)"
if prepare_module "$CACHE_TD11" "software-architecture"; then
  TD11_OUT="$(cd "$LAB_TD11" && VIBEFLOW_CACHE="$CACHE_TD11" bash "$INSTALLER" --dry-run install software-architecture 2>/dev/null)"
  if printf '%s\n' "$TD11_OUT" | "$GREP" -qE '^\[plan\] \+ .*\.vibeflow-installed' \
     && ! printf '%s\n' "$TD11_OUT" | "$GREP" -qE '^\[plan\] ~ .*\.vibeflow-installed'; then
    ok "TD11 : F-04 — .vibeflow-installed annoncé au verbe + (création) sur lab vierge, jamais ~"
  else
    ko "TD11 : F-04 — verbe .vibeflow-installed incorrect sur lab vierge — sortie : $(printf '%s' "$TD11_OUT" | "$GREP" -E 'vibeflow-installed')"
  fi
else
  skip "TD11 : software-architecture non copiable dans le cache de test"
fi
rm -rf "$LAB_TD11" "$CACHE_TD11"

# ---------------------------------------------------------------------------
# TD12 (F-06) — `--dry-run=true` (forme refusée par D-31-06) sort en erreur NOMMÉE (message
# distinct du fourre-tout d'usage générique), jamais un rc=1 muet indiscernable d'un usage invalide
# quelconque.
# ---------------------------------------------------------------------------
LAB_TD12="$(mktemp -d)"
CACHE_TD12="$(mktemp -d)"
if prepare_module "$CACHE_TD12" "software-architecture"; then
  TD12_ERR="$(mktemp)"
  (cd "$LAB_TD12" && VIBEFLOW_CACHE="$CACHE_TD12" bash "$INSTALLER" --dry-run=true install software-architecture) >/dev/null 2>"$TD12_ERR"
  TD12_RC=$?
  if [ "$TD12_RC" -eq 1 ] && "$GREP" -qE 'dry-run' "$TD12_ERR" && "$GREP" -qiE 'valeur' "$TD12_ERR"; then
    ok "TD12 : F-06 — --dry-run=true refusé (rc=1) avec message nommant la forme invalide"
  else
    ko "TD12 : F-06 — --dry-run=true : rc=$TD12_RC, message non conforme — voir $TD12_ERR"
  fi
  rm -f "$TD12_ERR"
else
  skip "TD12 : software-architecture non copiable dans le cache de test"
fi
rm -rf "$LAB_TD12" "$CACHE_TD12"

# ---------------------------------------------------------------------------
# TD13 (couverture manquante, mandat) — `--scope user` : chemin du plan ABSOLU et RÉSOLU (jamais
# une variable non expansée type "$HOME", jamais un chemin relatif) — seul scope où TARGET_ROOT est
# absolu (D-31-05 le nomme comme le plus grave en cas d'ambiguïté). HOME isolé (fakehome) : le
# --dry-run ne doit RIEN écrire, ni sous fakehome ni sous le vrai $HOME (jamais touché ici).
# ---------------------------------------------------------------------------
LAB_TD13="$(mktemp -d)"
FAKEHOME_TD13="$LAB_TD13/fakehome"
CACHE_TD13="$(mktemp -d)"
mkdir -p "$FAKEHOME_TD13"
if prepare_module "$CACHE_TD13" "software-architecture"; then
  TD13_OUT="$(cd "$LAB_TD13" && HOME="$FAKEHOME_TD13" VIBEFLOW_CACHE="$CACHE_TD13" bash "$INSTALLER" --scope user --dry-run install software-architecture 2>/dev/null)"
  TD13_EXPECT="[plan] + $FAKEHOME_TD13/.claude/skills/software-architecture/SKILL.md"
  if printf '%s\n' "$TD13_OUT" | "$GREP" -qF "$TD13_EXPECT" \
     && ! printf '%s\n' "$TD13_OUT" | "$GREP" -qE '\$HOME' \
     && [ ! -d "$FAKEHOME_TD13/.claude" ]; then
    ok "TD13 : --scope user — chemin du plan absolu et résolu (fakehome), aucune écriture (D-31-06)"
  else
    ko "TD13 : --scope user — chemin du plan incorrect ou écriture détectée — sortie : $(printf '%s' "$TD13_OUT" | "$GREP" -E 'SKILL\.md')"
  fi
else
  skip "TD13 : software-architecture non copiable dans le cache de test"
fi
rm -rf "$LAB_TD13" "$CACHE_TD13"

# ---------------------------------------------------------------------------
# T0 — anti-vert-à-vide (contrat F13) : la suite doit compter au moins une assertion.
# ---------------------------------------------------------------------------
if [ "$((pass + fail))" -eq 0 ]; then
  echo "== ANTI-VERT-À-VIDE : aucune assertion exécutée (pass+fail=0) =="
  exit 1
fi

# ---------------------------------------------------------------------------
echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ]
