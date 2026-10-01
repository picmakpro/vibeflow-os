#!/usr/bin/env bash
# fanout-state-integrity.sh — DÉFINITION UNIQUE du balayage par sujet. À SOURCER, jamais à exécuter.
#
# ROLE (P412-D-04, décision du manager, choix technique — pas un arbitrage humain) :
# le balayage « un invariant d'intégrité par compartiment » vivait en DEUX copies identiques dans
# `.github/workflows/ci.yml` (l'étape check-state-integrity et la section R5 de l'étape des gates
# workstream-aware). Une troisième copie était interdite : la preuve d'usage WSCH-04 doit jouer LE
# balayage de la CI avec le vrai moteur, dans le job `tests`. Il n'en reste donc qu'une, ici.
#
# CONSOMMATEURS :
#   - l'étape check-state-integrity de ci.yml (job gates) ;
#   - la section R5 de l'étape « Gates workstream-aware sur un arbre RÉELLEMENT partitionné » (job gates) ;
#   - la suite test-split-planning.sh (cas W, plan 41.2-04).
#
# CONTRAT DES TROIS FONCTIONS (repris des commentaires du bloc ci-dessous) :
#   is_non_init <fichier d'état>      rc 0 = non-initialisé, rc 1 = pas ce cas
#   ws_has_content <dossier>          rc 0 = contenu à côté de l'état, rc 1 = rien
#   fanout_check_state_integrity <lab_root>
#                                     bilan sur stdout ; rc 0 = 0 écart, rc 1 = au moins un
#
# EFFETS DE BORD AU CHARGEMENT : uniquement la variable `_FSI_LIB_DIR` et le chargement de la
# politique de nom de workstream (workstream-policy.sh). Ce fichier ne pose ni `set -e` ni `set -u` :
# l'appelant décide ; le corps reste propre sous `set -eu`, comme en CI. Compatible bash 3.2.
#
# RÉSOLUTION : `_FSI_LIB_DIR` vient de BASH_SOURCE[0], jamais du cwd — la lib se source depuis
# n'importe quel répertoire (T-41.2-06). Politique introuvable => `::error::` + `return 2`.

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  echo "fanout-state-integrity.sh est une bibliothèque à SOURCER (. fanout-state-integrity.sh), pas à exécuter." >&2
  exit 64
fi

_FSI_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -r "$_FSI_LIB_DIR/workstream-policy.sh" ]; then
  . "$_FSI_LIB_DIR/workstream-policy.sh"
elif [ -r "$_FSI_LIB_DIR/../../planning-core/scripts/workstream-policy.sh" ]; then
  . "$_FSI_LIB_DIR/../../planning-core/scripts/workstream-policy.sh"
else
  echo "::error::fanout-state-integrity.sh : workstream-policy.sh introuvable (ni voisin, ni dans planning-core)" >&2
  return 2
fi

# Classification D-02 INCONDITIONNELLE, par lecture directe du frontmatter — jamais une
# dépendance de forme sur un libellé que `check-state-integrity.sh` n'émet pas (a2, D-04 ;
# mesuré : ce script n'émet JAMAIS la sous-chaîne « non initialis »). Variables locales et
# préfixées `_ini_` : `f`/`fm`/`keys`/`nkeys` en globales écraseraient les compteurs d'une
# étape appelante sans un mot.
is_non_init() { # <fichier STATE.md> -> rc 0 = non-initialisé, rc 1 = pas ce cas
  local _ini_f="$1" _ini_fm _ini_keys _ini_nkeys
  [ -r "$_ini_f" ] || return 1
  _ini_fm="$(awk '/^---[[:space:]]*$/{n++; if(n==1) next; if(n==2) exit} {print}' "$_ini_f")"
  _ini_keys="$(printf '%s\n' "$_ini_fm" | awk -F: 'NF>=2{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$1); print $1}' | sort -u | awk 'NF')"
  _ini_nkeys="$(printf '%s\n' "$_ini_keys" | wc -l | tr -d ' ')"
  [ "$_ini_nkeys" -eq 2 ] || return 1
  printf '%s\n' "$_ini_keys" | grep -qx 'workstream' || return 1
  printf '%s\n' "$_ini_keys" | grep -qx 'created' || return 1
  return 0
}

# D-02 AMENDÉE le 2026-09-23 (arbitrage Samuel, AskUserQuestion session principale, Q1
# option b) : « non initialisé » porte sur le FRONTMATTER SEUL. La clause « ET aucun
# ROADMAP/REQUIREMENTS de contenu » est RETIRÉE — elle classait `gouvernance` CORROMPU
# (STATE.md à 2 clés MAIS ROADMAP.md de 180 lignes, REQUIREMENTS.md, phases/), contre le
# critère tranché « un compartiment neuf ne doit jamais rougir ». Ce que `is_non_init`
# laisse passer EN SILENCE est le cas INVERSE — un STATE.md TRONQUÉ jusqu'aux 2 clés
# nominales avec du contenu bien rempli à côté. Les deux ont la MÊME SIGNATURE SUR DISQUE.
# D'où le VERDICT NOMMÉ D'AMBIGUÏTÉ plus bas : une NOTICE qui nomme les DEUX lectures et
# n'en choisit AUCUNE. (Discriminer par l'historique git a été explicitement écarté : cela
# ferait dépendre le verdict d'un passé que rien ne garantit présent.)
ws_has_content() { # <dossier compartiment> -> rc 0 = du contenu existe à côté du STATE.md
  local _wsc_d="$1"
  if [ -s "$_wsc_d/ROADMAP.md" ]; then return 0; fi
  if [ -s "$_wsc_d/REQUIREMENTS.md" ]; then return 0; fi
  if [ -d "$_wsc_d/phases" ] && [ -n "$(ls -A "$_wsc_d/phases" 2>/dev/null || true)" ]; then return 0; fi
  return 1
}
# NOTE : un compartiment SANS STATE.md du tout (`[ -r ... ]` faux) n'est PAS classé
# non-init — il tombe au script, qui rougira. C'EST VOULU : l'absence totale de STATE.md
# n'est ni la facture nominale de `workstream create` (qui en écrit TOUJOURS un) ni un
# état sain — c'est corrompu par construction, et l'échec audible est la posture
# fail-closed cohérente avec le reste de cette étape.

# Toutes les variables/fonctions internes sont locales et préfixées `_fsi_` : appelée
# depuis une étape qui tient ses propres compteurs `fail`/`note`, cette fonction ne doit
# JAMAIS pouvoir en effacer un (défaut déjà introduit puis fermé dans ce dépôt).
fanout_check_state_integrity() { # <lab_root> -> bilan sur stdout, rc 0 = 0 écart, 1 = >=1
  local lab_root="$1" lab_root_abs planning_dir
  local _fsi_fail=0 _fsi_n=0 _fsi_rc=0 _fsi_wsdir _fsi_rel _fsi_statefile_rel _fsi_out _fsi_rc2 _fsi_ws_list
  lab_root_abs="$(cd "$lab_root" && pwd)"
  planning_dir="$lab_root_abs/.planning"
  _fsi_note() { echo "::error::check-state-integrity : $1"; _fsi_fail=$((_fsi_fail + 1)); }
  _fsi_ws_list="$(vf_ws_enumerate "$planning_dir")" || _fsi_rc=$?
  # rc=3 EST NOMINAL, JAMAIS UN ÉCART : le plan 41.1-01, PRODUCTEUR de la primitive,
  # déclare « 3 = SILENCE, workstreams/ absent (dépôt non partitionné, ÉTAT NOMINAL) ».
  # Le traiter comme un 2 ferait rougir la CI sur l'état que son propre producteur déclare
  # nominal — masqué sur CE dépôt (partitionné), mais la fixture voisine du MÊME job
  # construit des arbres NON partitionnés (BLOC 2a « non-régression FLAT »).
  case "$_fsi_rc" in
    0) : ;;
    3)
      echo "::notice::$planning_dir : aucun compartiment de workstream (workstreams/ absent) — dépôt NON PARTITIONNÉ, état NOMINAL. Rien à mesurer, AUCUN écart."
      return 0
      ;;
    2)
      echo "::error::vf_ws_enumerate $planning_dir : workstreams/ présent mais AUCUN compartiment vérifiable (lien symbolique, illisible, ou vide après filtrage anti-lien) — NON VÉRIFIABLE, jamais un vert par défaut"
      return 1
      ;;
    *)
      echo "::error::vf_ws_enumerate $planning_dir : code de sortie imprévu ($_fsi_rc, attendu 0/2/3) — NON VÉRIFIABLE"
      return 1
      ;;
  esac
  while IFS= read -r _fsi_wsdir; do
    [ -n "$_fsi_wsdir" ] || continue
    _fsi_n=$((_fsi_n + 1))
    _fsi_rel="${_fsi_wsdir#"$lab_root_abs"/}"
    _fsi_statefile_rel="$_fsi_rel/STATE.md"
    if is_non_init "$_fsi_wsdir/STATE.md"; then
      echo "::notice::$_fsi_rel : non initialisé (D-02 amendée, frontmatter réduit à workstream:+created:), jamais compté comme écart (D-06)"
      if ws_has_content "$_fsi_wsdir"; then
        echo "::notice::$_fsi_rel : AMBIGUITE-D02 — frontmatter nominal MAIS du contenu existe à côté (ROADMAP.md / REQUIREMENTS.md / phases/). DEUX lectures sont possibles et AUCUNE n'est choisie ici : (i) compartiment NEUF alimenté par carve-out ; (ii) compartiment TRAVAILLÉ dont le STATE.md a été TRONQUÉ en plein cycle d'écriture. Les deux ont la même signature sur disque. Ceci est une NOTICE, PAS un échec — à lever à la main."
      fi
      continue
    fi
    _fsi_rc2=0
    _fsi_out="$(bash "$_FSI_LIB_DIR/check-state-integrity.sh" --path "$lab_root_abs" --file "$_fsi_statefile_rel" 2>&1)" || _fsi_rc2=$?
    echo "== check-state-integrity $_fsi_rel : rc=$_fsi_rc2 =="; printf '%s\n' "$_fsi_out"
    case "$_fsi_rc2" in
      0) : ;;
      3)
        # CONSOMMATION DU SIGNAL produit par le plan 41.1-09 (d'où le depends_on).
        # 3 = conforme SOUS RÉSERVE : l'Invariant 1 (non-régression des compteurs,
        # ADR-063) a été SAUTÉ faute de baseline à HEAD. Ce N'EST PAS un écart — le faire
        # échouer rougirait sur TOUT compartiment neuf et casserait l'invariant à trois
        # états de D-02. Ce qui change : ne juger QUE le code de sortie laissait
        # l'annonce du gate sur stderr SEULEMENT, donc INVISIBLE AU VERDICT.
        echo "::notice::$_fsi_rel : INVARIANT1-SAUTE — conforme SOUS RÉSERVE, aucune baseline à HEAD (compartiment absent de HEAD ?). Seul l'Invariant 2 (compte de lignes '^Phase:') a été vérifié. Ceci est une NOTICE, PAS un écart."
        ;;
      *)
        _fsi_note "$_fsi_rel : rc=$_fsi_rc2, attendu 0 (conforme), 3 (Invariant 1 sauté) ou non-initialisé détecté en amont par is_non_init"
        ;;
    esac
  done <<< "$_fsi_ws_list"
  [ "$_fsi_n" -ge 1 ] || { echo "::error::aucun compartiment énuméré — vérité vide"; return 1; }
  echo "== BILAN check-state-integrity ($lab_root_abs) : $_fsi_fail écart(s) sur $_fsi_n compartiment(s) =="
  [ "$_fsi_fail" -eq 0 ]
}
