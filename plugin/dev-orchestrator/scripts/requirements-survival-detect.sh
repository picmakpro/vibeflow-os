#!/usr/bin/env bash
# requirements-survival-detect.sh — primitive PARTAGÉE de détection de survie du ledger (LEDG-02).
# À SOURCER, jamais à exécuter (même contrat que workstream-policy.sh). Deux consommateurs, tous
# deux dans dev-orchestrator (A-18-03) : check-requirements-survival.sh (ce plan) et
# restore-requirements-ledger.sh (rattrapage, plan 18-02).
#
# Expose vf_ledger_state <planning_dir>. Contrat de retour : CODE DE SORTIE discriminant + variables
# VF_LEDGER_* — jamais de parsing de sortie texte entre scripts (D-18-06, une primitive deux
# consommateurs).
#
#   Code | VF_LEDGER_STATE     | Sens
#   0    | absent_after_close  | jalon déclaré clos ET REQUIREMENTS.md absent
#   1    | nominal             | rien à signaler
#   2    | unreadable          | état illisible — bruyant, jamais un vert (VF_LEDGER_REASON renseigné)
#   3    | ids_missing         | REQUIREMENTS.md présent, ≥1 ID garanti/voyageur disparu sans trace
#
# Variables toujours vidées en tête d'appel, jamais héritées d'un appel précédent :
#   VF_LEDGER_STATE, VF_LEDGER_MILESTONE, VF_LEDGER_ARCHIVE, VF_LEDGER_ARMED, VF_LEDGER_REASON,
#   VF_LEDGER_MISSING_IDS, VF_LEDGER_MISSING_COUNT.
#
# Lecteur d'absence, jamais juge de contenu (D-18-10) : présence/absence d'un ID ou d'un fichier
# est binaire et falsifiable. Aucun statut ni prose n'est jamais lu ou jugé, sauf le diff d'IDs
# (A-18-08) qui ne lit QUE des IDs et le jeton littéral `caduc`, jamais une phrase.
#
# Marqueur d'armement (D-18-09, A-18-02, checkpoint T1 tranché par Samuel 2026-08-18 — option-a) :
# fichier-sentinelle VERSIONNÉ dans le lab, <planning_dir>/.requirements-survival-armed. Sa lecture
# est confinée à cette unique fonction. Précédent de la MÉCANIQUE « marqueur par fichier-sentinelle »
# dans ce dépôt : la sentinelle d'opt-in de /vf-notify (scope user, HORS dépôt) et le marqueur
# d'install scripts/.vibeflow-installed (vit sous .claude/, EXCLU du dépôt par .gitignore:20) — ni
# l'un ni l'autre n'est un précédent de sentinelle VERSIONNÉE PAR GIT : c'est bien le premier objet
# de ce type dans ce repo (cf. plugin/dev-orchestrator/AGENT.md).
#
# T-18-01/T-18-02 : le libellé du jalon extrait de MILESTONES.md est validé contre la liste blanche
# stricte ^[0-9A-Za-z._ -]{1,80}$ (modèle sanitize_value de check-dev-bootstrap.sh) AVANT toute
# réimpression et avant toute construction de chemin d'archive. Échec → unreadable, jamais la valeur
# brute imprimée ou concaténée. `/` est EXCLU de cette classe (correctif 2026-08-18) : une forme
# antérieure l'admettait aux côtés de `.`, ce qui laissait passer une traversée `../` intégrale — la
# liste blanche ne bornait alors QUE la réimpression de métacaractères, jamais la traversée.
#
# T-18-03 : lecture de MILESTONES.md bornée à 400 lignes (awk, garde anti-gel SessionStart). Le
# diff d'IDs (A-18-08) parcourt l'archive et le vivant chacun UNE seule fois côté awk, sans boucle
# imbriquée sur le contenu de dépôt.

# vf_ancestor_symlink_found <path> <boundary_dir> — confinement de traversée symlink D'ANCÊTRE
# (correctif 2026-08-18, revue tour 2, BLOQUANT). La garde `[ -f "$archive" ] && [ ! -L "$archive" ]`
# plus bas ne teste QUE le fichier FEUILLE — jamais les répertoires intermédiaires du chemin. Un
# ancêtre symlinké (ex. `.planning/milestones -> /chemin/hors/lab`) traversait cette garde intacte :
# le fichier feuille pointé par la traversée n'est lui-même pas un lien, seul un composant du CHEMIN
# l'est. Reproduit trois fois (revue, audit, exécution directe) : `.planning/milestones` symlinké
# vers un répertoire externe, jalon déclaré clos, `restore-requirements-ledger.sh --write` lisait et
# écrivait du contenu venu de HORS du lab dans `.planning/REQUIREMENTS.md`, fichier tracké git.
# Vecteur aggravant : un symlink RELATIF sous `.planning/` (non ignoré par .gitignore) peut être
# commité et déclenché par un simple `git pull` au SessionStart suivant — pas seulement un
# scénario "l'attaquant a déjà un accès en écriture".
#
# Remonte les composants un par un depuis dirname(<path>) jusqu'à <boundary_dir> INCLUS et refuse
# (return 0 = trouvé) dès qu'un composant est un lien symbolique. AUCUN `realpath` (ADR-054,
# précédent symlink-ancestor-bypasses-target-root-check banni pour ce type de garde dans ce dépôt) :
# cette marche manuelle composant par composant est la forme retenue ici.
vf_ancestor_symlink_found() { # <path> <boundary_dir>
  local target="$1" boundary="$2" dir parent
  dir="$(dirname "$target")"
  while :; do
    [ -L "$dir" ] && return 0
    if [ "$dir" = "$boundary" ] || [ "$dir" = "." ] || [ "$dir" = "/" ]; then
      return 1
    fi
    parent="$(dirname "$dir")"
    [ "$parent" = "$dir" ] && return 1
    dir="$parent"
  done
}

vf_ledger_state() { # <planning_dir>
  local planning_dir="$1"
  VF_LEDGER_STATE="" VF_LEDGER_MILESTONE="" VF_LEDGER_ARCHIVE="" VF_LEDGER_ARMED=""
  VF_LEDGER_REASON="" VF_LEDGER_MISSING_IDS="" VF_LEDGER_MISSING_COUNT="0"

  VF_LEDGER_ARMED=0
  [ -f "$planning_dir/.requirements-survival-armed" ] && VF_LEDGER_ARMED=1

  local milestones="$planning_dir/MILESTONES.md"
  if [ ! -d "$planning_dir" ] || [ ! -f "$milestones" ]; then
    VF_LEDGER_STATE="nominal"; return 1
  fi

  # Premier titre H2 CLOS rencontré de haut en bas (le fichier est anté-chronologique par
  # convention) ; aucune date de prose n'est jamais lue — dater serait juger du contenu (D-18-10).
  local heading
  heading="$(awk '
    NR > 400 { exit }
    /^## / {
      any_h2 = 1
      if (index($0, "\xe2\x9c\x85") > 0 && !found) { print $0; found = 1; exit }
    }
    END { if (!found) print (any_h2 ? "__NOCLOSE__" : "__NOHEADING__") }
  ' "$milestones")"

  case "$heading" in
    __NOHEADING__) VF_LEDGER_STATE="unreadable"; VF_LEDGER_REASON="no_heading"; return 2 ;;
    __NOCLOSE__)   VF_LEDGER_STATE="nominal"; return 1 ;;
  esac

  local label
  label="$(awk -v line="$heading" 'BEGIN {
    s = line
    sub(/^## /, "", s)
    sub(/^[^0-9A-Za-z]*/, "", s)
    idx = index(s, "\xe2\x80\x94")
    if (idx > 0) s = substr(s, 1, idx - 1)
    gsub(/[ \t]+$/, "", s)
    print s
  }')"
  # Correction 2026-08-18 (revue de code + audit sécurité, bloquant #1) : `/` a été RETIRÉ de cette
  # classe. La forme précédente (`^[0-9A-Za-z._ /-]{1,80}$`) admettait `.` ET `/` SIMULTANÉMENT, ce
  # qui laisse passer une traversée `../` intégrale (ex. `agentique-v1.0-phases/../../../../outside/pwn`)
  # — prouvé par exécution avant ce correctif : le chemin d'archive interpolé plus bas (et
  # `restore-requirements-ledger.sh`, qui hérite de ce même libellé validé) lisait/écrivait alors
  # hors de `.planning/`. Aucun libellé de jalon CLOS de `.planning/MILESTONES.md` de ce dépôt n'a
  # jamais porté de `/` (vérifié, les 8 titres H2 clos réellement présents au moment de ce correctif :
  # `agentique-v1.0`, `vf-routing`, `gsd-migration`, `hors-milestone`, `memory-swarm-rnd`,
  # `dev-doctrine`, `install-ux-v1.0`, `vfdo-v1.0`) : le retirer ne restreint aucun cas réel.
  # Correction 2026-08-18 (revue tour 2, mineur) : `fiabilite-v1.0` retiré de cette liste — overclaim,
  # ce jalon n'apparaît PAS dans MILESTONES.md (encore ouvert au moment de ce correctif), il n'a
  # donc jamais été « vérifié » au sens de cette phrase (aucun titre H2 clos à examiner pour lui).
  if ! printf '%s' "$label" | grep -Eq '^[0-9A-Za-z._ -]{1,80}$'; then
    VF_LEDGER_STATE="unreadable"; VF_LEDGER_REASON="label_rejected"; return 2
  fi
  VF_LEDGER_MILESTONE="$label"

  local archive="$planning_dir/milestones/${label}-REQUIREMENTS.md"
  local live="$planning_dir/REQUIREMENTS.md"

  if [ -f "$live" ]; then
    # Trace bien formée (D-18-12) : le jeton, exactement une espace, puis une étiquette conforme
    # à ^[0-9A-Za-z._ -]{1,80}$ (MÊME classe que le libellé de jalon l. 92 — correctif 2026-08-18,
    # revue de code : les deux classes étaient incohérentes), ancrée en FIN de ligne (`$`) — sans
    # cette ancre, un suffixe garbage (`carried-from: v1.2!!!GARBAGE`) matchait comme préfixe bien
    # formé au lieu de tomber en illisible, l'inverse exact de D-18-10. Toute ligne portant le jeton
    # hors de cette forme → illisible — SAUF une mention NUE du jeton (ex. prose documentant la
    # convention entre backticks, sans valeur après les deux-points : cas réel de
    # .planning/REQUIREMENTS.md:932, "trace `carried-from:`") : ce n'est pas une tentative de trace,
    # donc pas un motif d'illisibilité (D-18-10 : lire une absence, jamais juger la prose qui la
    # décrit).
    if grep -n 'carried-from:' "$live" 2>/dev/null \
        | grep -vE 'carried-from:`|carried-from:[[:space:]]*$' \
        | grep -vE 'carried-from: [0-9A-Za-z._ -]{1,80}$' | grep -q .; then
      VF_LEDGER_STATE="unreadable"; VF_LEDGER_REASON="trace_malformed"; return 2
    fi
    if [ -f "$archive" ] && [ ! -L "$archive" ] && ! vf_ancestor_symlink_found "$archive" "$planning_dir"; then
      local diff_out missing_count missing_list
      diff_out="$(awk '
        FNR == NR {
          if ($0 ~ /^## Traceability[ \t]*$/) { intrace = 1; next }
          if (intrace == 0) {
            if (match($0, /^- \[.\] \*\*[A-Z]+-[0-9]+\*\*/)) {
              line = $0
              if (match(line, /[A-Z]+-[0-9]+/)) {
                id = substr(line, RSTART, RLENGTH)
                bodyline[id] = line; bodyseen[id] = 1
              }
            }
          } else {
            if (match($0, /^\| [A-Z]+-[0-9]+ \|/)) {
              line = $0
              if (match(line, /[A-Z]+-[0-9]+/)) {
                id = substr(line, RSTART, RLENGTH)
                traceline[id] = line; traceseen[id] = 1
              }
            }
          }
          next
        }
        {
          lline = $0
          while (match(lline, /\*\*[A-Z]+-[0-9]+\*\*/)) {
            tok = substr(lline, RSTART + 2, RLENGTH - 4)
            livepresent[tok] = 1
            lline = substr(lline, RSTART + RLENGTH)
          }
        }
        END {
          mc = 0; ml = ""
          for (id in bodyseen) {
            if (!(id in traceseen)) continue
            combo = tolower(bodyline[id] "\n" traceline[id])
            if (combo ~ /caduc/) continue
            if (id in livepresent) continue
            mc++
            ml = (ml == "" ? id : ml " " id)
          }
          printf "%d\t%s\n", mc, ml
        }
      ' "$archive" "$live")"
      missing_count="${diff_out%%$'\t'*}"
      missing_list="${diff_out#*$'\t'}"
      case "$missing_count" in ''|*[!0-9]*) missing_count=0 ;; esac
      if [ "$missing_count" -gt 0 ]; then
        VF_LEDGER_STATE="ids_missing"
        VF_LEDGER_ARCHIVE="$archive"
        # Ordre déterministe (correctif 2026-08-18, revue de code) : `for (id in bodyseen)` en awk
        # n'a jamais d'ordre garanti (gawk et BSD/mawk le parcourent différemment) — le COMPTE
        # (missing_count) restait juste mais QUELS IDs apparaissaient dans les 5 premiers variait
        # selon la plateforme d'exécution (CI Linux/gawk vs macOS/awk). Trié ici, une seule fois,
        # avant toute troncature en aval (check-requirements-survival.sh).
        missing_list="$(printf '%s\n' "$missing_list" | tr ' ' '\n' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ *$//')"
        VF_LEDGER_MISSING_IDS="$missing_list"
        VF_LEDGER_MISSING_COUNT="$missing_count"
        return 3
      fi
    fi
    VF_LEDGER_STATE="nominal"; return 1
  fi

  # REQUIREMENTS.md ABSENT — chemin construit à partir du libellé DÉJÀ validé (T-18-02). Garde
  # d'ancêtre symlinké appliquée ici aussi (vf_ancestor_symlink_found) : sans elle, l'archive
  # atteinte via un ancêtre lien serait proposée pour restauration alors même que le fichier feuille
  # n'est pas lui-même un lien.
  if [ -f "$archive" ] && [ ! -L "$archive" ] && ! vf_ancestor_symlink_found "$archive" "$planning_dir"; then
    VF_LEDGER_ARCHIVE="$archive"
  fi
  VF_LEDGER_STATE="absent_after_close"; return 0
}

# vf_ledger_classify <ligne_de_statut_du_corps> <ligne_de_traçabilité_correspondante> — deuxième
# consommateur de cette primitive (restore-requirements-ledger.sh, plan 18-02, LEDG-01), classe une
# exigence archivée en un DESTIN de rattrapage. Zéro normalisation (D-18-13) : cette fonction ne
# réécrit jamais le texte — elle rend un code, l'appelant écrit la ligne SOURCE verbatim.
#
#   Précédence FIGÉE, corrigée le 2026-08-18 en DEUX temps sur mesure (rejeu réel sur l'archive
#   agentique-v1.0) — la case à cocher a été essayée comme signal primaire puis ABANDONNÉE : mesuré,
#   134/136 IDs de cette archive sont cochés [x] (0 non coché, 2 partiels [~]) — une archive de
#   jalon CLOS a tout coché à la clôture, la case y est donc CONSTANTE et sans pouvoir discriminant.
#   Le signal retenu est « tout statut non reconnu comme livré VOYAGE » (route 1), avec un
#   vocabulaire élargi de formes reconnues comme livrées :
#     1. CADUQUE (code 2) — le jeton `caduc` (insensible à la casse) apparaît sur la ligne de CORPS
#        OU la ligne de TRAÇABILITÉ, quel que soit l'état de la case. Cas réel : VERB-02 ne porte
#        `caduc` QUE sur sa traçabilité — les deux lignes doivent être inspectées, jamais le corps
#        seul. Précédence ABSOLUE : gagne toujours, même sur une case cochée.
#     2. VOYAGE (code 1) — case EXPLICITEMENT NON cochée `[ ]` : jamais livrée, aucune ambiguïté,
#        départage immédiat sans lire la traçabilité.
#     3. GARANTIE (code 0) — case `[x]` ou `[~]` ET la traçabilité contient (insensible à la casse)
#        `complete` ou `done` (couvre `Complete`, `Done — …`, `Spike done — …`), OU le corps porte
#        le jeton littéral `Livré v` — mesuré : 48 `Complete` + 44 `Done` (dont les variantes
#        `Done (doctrinal)`, `Spike done`) sur l'archive réelle. Sinon repli sur 4.
#     4. VOYAGE (code 1, repli par défaut) — case cochée mais statut NI caduc NI reconnu comme
#        livré : couvre `Planned — plan NN` (19 IDs mesurés, TOUS cochés — la route « case seule »
#        les aurait classés garantie à tort, zéro exigence n'aurait voyagé), `Partiel` (GSDC-08),
#        la prose non reconnue, et l'ABSENCE de ligne de traçabilité (l'appelant passe une chaîne
#        vide, qui ne matche jamais `complete`/`done` — NOTR-01-like, zéro perte plutôt qu'un
#        classement halluciné).
#     5. FORME NON RECONNUE (code 3) — repli ULTIME, réservé aux lignes de corps qui ne portent
#        AUCUNE case reconnaissable (ni `[x]`, ni `[ ]`, ni `[~]`).
#
#   CONTRAINTE NON NÉGOCIABLE (mesurée le 2026-08-18, DEUX fois, sur l'archive réelle) : une
#   exigence archivée absente du fichier reconstitué est INVISIBLE (contre un ID sur-inclus dans la
#   mauvaise section, visible et corrigible) — c'est le mode d'échec exact que cette phase existe
#   pour empêcher. Le contrat d'origine (Complete/Livré v uniquement, jamais Done) perdait 86/136
#   (63 %) en PRÉSENCE. Le contrat « case seule » essayé ensuite atteignait 136/136 en présence mais
#   se trompait en DESTINATION : les 19 `Planned` (tous cochés) auraient été classées garanties,
#   zéro exigence n'aurait voyagé — l'inverse exact de D-18-11. Deux tests distincts gardent
#   désormais les deux axes (présence ET destination), voir test-restore-requirements-ledger.sh.
#   D-18-13 tient : reconnaître un statut n'est pas le réécrire — la ligne imprimée par l'appelant
#   reste la ligne SOURCE verbatim, `Done — plans 24-01 et 24-12` n'est JAMAIS réécrit `Complete`.
vf_ledger_classify() { # <ligne_corps> <ligne_traçabilité>
  local body="$1" trace="$2" combo
  combo="$body
$trace"
  # Borne de mot en tête (correctif 2026-08-18, revue tour 2, MINEUR #5) : incohérent jusqu'ici avec
  # le `\b` déjà appliqué à `complete|done` plus bas dans ce MÊME commit — alignement de forme.
  # Bornée en TÊTE SEULEMENT (`\bcaduc`, pas `\bcaduc\b`) : la forme plurielle `caducs` (masc. plur.,
  # `caduc` + `s`) DOIT rester matchée — une borne de FIN l'exclurait puisque `c` et `s` sont tous
  # deux des caractères de mot (aucune frontière entre eux), prouvé par exécution :
  # `printf 'caducs' | grep -qE '\bcaduc\b'` échoue, `\bcaduc` seul réussit. La forme féminine
  # `caduque` n'est PAS concernée par ce choix : elle ne contient de toute façon PAS la sous-chaîne
  # `caduc` (alternance c→qu au féminin, comme `public`/`publique`) — bornée ou non, elle ne
  # matchait déjà pas avant ce correctif.
  if printf '%s' "$combo" | grep -qiE '\bcaduc'; then
    return 2
  fi
  case "$body" in
    '- [ ] '*)
      return 1
      ;;
    '- [x] '*|'- [X] '*|'- [~] '*)
      # `[X]` majuscule ajouté (correctif mineur 2026-08-18, revue de code) : forme équivalente à
      # `[x]` non reconnue jusqu'ici, repli code 3 évitable — bruit de triage.
      # Bornes de mot (correctif 2026-08-18, revue de code) : `complete|done` sans bornes matchait
      # aussi en sous-chaîne de `incomplete`, ce qui aurait classé un statut « Incomplete — reste 2
      # items » en Garantie (perte silencieuse du carried-from:) — exactement le défaut que cette
      # phase existe pour éliminer.
      if printf '%s' "$trace" | grep -qiE '\bcomplete\b|\bdone\b'; then return 0; fi
      if printf '%s' "$body" | grep -q 'Livré v'; then return 0; fi
      return 1
      ;;
    *)
      return 3
      ;;
  esac
}
