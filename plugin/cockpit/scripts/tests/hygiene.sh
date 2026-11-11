# hygiene.sh — hygiène des processus des suites du cockpit (P67-G1). À « sourcer » APRÈS la définition de WORK (et du trap EXIT qui appelle vf_hyg_fin).
# Contrat : une suite arrête TOUT ce qu'elle lance, et ROUGIT si quelque chose survit. La marque d'une suite est le nom de base de son
# dossier temporaire (mktemp -d : « tmp.<alphanumérique> »), unique à chaque exécution : elle figure dans la ligne de commande de ses serveurs
# (chemin absolu du lab) et de ses Chrome (profil « cdp-chrome-<marque>- », cf. chrome-session.mjs). Aucun compte global de la machine.
# GARDE-FOUS (incident du 2026-11-02 : une marque vide faisait passer tout processus de la machine pour « de la suite », puis TERM/KILL à tous) :
#   G1 la marque atteint awk par son environnement (ps | VF_T=… awk), jamais par un préfixe qui ne vise que ps
#   G2 marque validée avant tout usage, sur la chaîne ENTIÈRE (tmp. + ≥ 6 alphanumériques, une seule ligne) — sinon FAIL nommé, plus rien n'est listé ni tué
#   G3 plafond anti-massacre : plus de VF_HYG_MAX (20) processus marqués → aucun kill, FAIL « marque trop large ». La garde qui compte est l'assertion
#      H1 de vf_hyg_assert (rouge). Dans vf_hyg_fin (trap EXIT) le message part sur stderr mais le code de sortie de la suite n'en est pas changé.
#      Limite assumée : au-delà de 20 processus marqués (≈ 3 Chrome fuités) le filet ne tue plus rien, la fuite reste après le rouge, à nettoyer
#      à la main (ps -eo pid,args | grep <marque>) ; avec G2, M1 et m1 le plafond ne protège plus que d'une marque valide mais trop large.
#   G4 jamais $$, $PPID, BASHPID ni un ancêtre du shell de la suite, jamais pid ≤ 1
#   G5 VF_HYG_DRY=1 : afficher ce qui serait tué, ne rien tuer
#   M1 « PID réutilisé » : aucun signal à un PID dont la ligne de commande COURANTE ne porte pas la marque (contrôle juste avant CHAQUE envoi,
#      dans vf_hyg_kill, pour tout appelant) ; pas de KILL sur la foi d'un `kill -0` ; un PID arrêté sort de PIDS (vf_hyg_stop)
#   m1 ne sont visés que les descendants de la suite et les orphelins (arbre dont le sommet, sous pid 1, porte la marque) : un tail ou un éditeur
#      étranger ouvert sur le dossier temporaire reste intact. Limite : un orphelin n'est reconnu que s'il est rattaché à pid 1 (launchd, init)
#   m2 témoin positif : le pid de la suite doit figurer dans la sortie de ps, sinon FAIL nommé (H-0) — jamais un « aucun survivant » aveugle
#   vf_hyg_init      valide et pose la marque, exporte VF_CDP_TAG, arme les signaux, compte « avant » (+ fuite injectée VF_TEST_INJECTER_FUITE=1|chrome)
#   vf_hyg_vivants   liste « pid args » des processus vivants portant la marque (descendants ou orphelins, hors la suite et ses ancêtres)
#   vf_hyg_stop      arrête UN pid (marqué) en cours de suite et le retire de PIDS — remplace tout `kill "$pid"; wait "$pid"`
#   vf_hyg_arreter   arrête les PID inscrits dans PIDS (attente bornée)
#   vf_hyg_assert    arrête les inscrits puis assert_eq : plus rien ne survit — un survivant est une fuite (nommé : pid et commande)
#   vf_hyg_fin       filet du trap EXIT : tue tout ce qui porte la marque (TERM puis KILL), jamais autre chose
VF_HYG_MAX=20
vf_hyg_tag_ok() {
  local LC_ALL=C t="${VF_HYG_TAG:-}"
  [ "${#t}" -ge 10 ] || return 1
  case "$t" in tmp.*) ;; *) return 1 ;; esac
  case "${t#tmp.}" in ''|*[!A-Za-z0-9]*) return 1 ;; esac
  return 0
}
vf_hyg_init() {
  VF_HYG_TAG="$(basename "${WORK:-}")"
  if ! vf_hyg_tag_ok; then echo "  ❌ FAIL — H-1 marque de suite invalide [${VF_HYG_TAG}] (attendu : tmp.<6+ alphanumériques>) — rien n'est lancé ni tué" >&2; VF_HYG_TAG=""; exit 1; fi
  if ! vf_hyg_ps_ok; then echo "  ❌ FAIL — H-0 ps inutilisable : le pid de la suite ($$) ne figure pas dans sa sortie — aucun survivant ne serait vu" >&2; exit 1; fi
  export VF_CDP_TAG="$VF_HYG_TAG"
  trap 'exit 130' INT; trap 'exit 143' TERM
  VF_HYG_AVANT="$(vf_hyg_vivants | wc -l | tr -d ' ')"
  case "${VF_TEST_INJECTER_FUITE:-}" in
    1) mkdir -p "$WORK/fuite"; echo 'setInterval(() => {}, 1000)' > "$WORK/fuite/serve.mjs"; node "$WORK/fuite/serve.mjs" >/dev/null 2>&1 </dev/null & ;;
    chrome) [ -n "${CHROME:-}" ] && { "$CHROME" --headless=new --no-sandbox --disable-gpu --no-first-run --user-data-dir="${TMPDIR:-/tmp}/cdp-chrome-$VF_HYG_TAG-fuite" about:blank >/dev/null 2>&1 </dev/null & } ;;
  esac
  return 0
}
# m2 : ps est utilisable si le pid de la suite figure dans sa sortie
vf_hyg_ps_ok() { ps -eo pid,ppid,args 2>/dev/null | awk -v me="$$" '$1 == me { f = 1 } END { exit !f }'; }
# ancêtres du shell courant (pid, ppid, …), un par ligne
vf_hyg_ancetres() { local self="${BASHPID:-$$}"; ps -eo pid,ppid | VF_ME="$$" VF_PP="$PPID" VF_B="$self" awk 'NR>1{pp[$1]=$2} END{n=split(ENVIRON["VF_ME"] " " ENVIRON["VF_PP"] " " ENVIRON["VF_B"],s," "); for(i=1;i<=n;i++){p=s[i]; k=0; while(p+0>1 && k<64){print p; p=pp[p]; k++}}}'; }
vf_hyg_vivants() {
  vf_hyg_tag_ok || return 0
  local self="${BASHPID:-$$}"   # le sous-shell courant (substitution de commande, tube) : sa chaîne d'ancêtres est protégée en entier
  ps -eo pid,ppid,args | VF_T="$VF_HYG_TAG" VF_ME="$$" VF_PP="$PPID" VF_B="$self" awk '
    BEGIN { t = ENVIRON["VF_T"]; ok = (length(t) >= 10 && t ~ /^tmp\.[A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9]+$/) }
    NR > 1 && $1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/ { pp[$1] = $2; a = $0; sub(/^ *[0-9]+ +[0-9]+ +/, "", a); arg[$1] = a; ord[++n] = $1 }
    END {
      if (!ok) exit   # un exit dans BEGIN exécuterait quand même END : la garde vit ici
      me = ENVIRON["VF_ME"]; m = split(me " " ENVIRON["VF_PP"] " " ENVIRON["VF_B"], s, " ")
      for (i = 1; i <= m; i++) { p = s[i]; k = 0; while (p + 0 > 1 && k < 64) { prot[p] = 1; pa[arg[p]] = 1; p = pp[p]; k++ } }
      for (j = 1; j <= n; j++) {
        q = ord[j]; if ((q in prot) || index(arg[q], t) == 0) continue
        if (arg[q] in pa) continue   # copie de nos propres shells (sous-shell de tube ou de substitution, avant exec) : même ligne de commande qu un protégé
        p = q; top = q; d = 0; k = 0
        while (p + 0 > 1 && k < 64) { if (p == me) d = 1; top = p; p = pp[p]; k++ }
        # m1 : descendant de la suite, ou arbre orphelin dont le sommet (rattaché à pid 1) porte la marque
        if (d || index(arg[top], t) > 0) print q " " arg[q]
      }
    }'
}
# M1 : la ligne de commande COURANTE du pid porte-t-elle la marque ?
vf_hyg_marque_p() {
  vf_hyg_tag_ok || return 1
  local a; a="$(ps -o args= -p "$1" 2>/dev/null)" || return 1
  case "$a" in *"$VF_HYG_TAG"*) return 0 ;; esac
  return 1
}
# vf_hyg_kill <signal> <pid>... : refuse pid ≤ 1, soi-même, le parent, les ancêtres et tout pid sans la marque ; VF_HYG_DRY=1 n'envoie rien
vf_hyg_kill() {
  local sig="$1" p anc; shift; anc=" $(vf_hyg_ancetres | tr '\n' ' ') "
  for p in "$@"; do
    case "$p" in ''|*[!0-9]*) continue ;; esac
    [ "$p" -gt 1 ] || continue
    case "$anc" in *" $p "*) continue ;; esac
    vf_hyg_marque_p "$p" || continue
    if [ -n "${VF_HYG_DRY:-}" ]; then echo "DRY kill -$sig $p"; continue; fi
    kill -"$sig" "$p" 2>/dev/null
  done
  return 0
}
# vf_hyg_stop <pid> : arrête un processus MARQUÉ (TERM, attente bornée, KILL s'il porte encore la marque) puis le retire de PIDS
vf_hyg_stop() {
  local p="${1:-}" q i n=()
  if vf_hyg_marque_p "$p"; then
    vf_hyg_kill TERM "$p"
    if [ -z "${VF_HYG_DRY:-}" ]; then
      for i in 1 2 3 4 5 6 7 8 9 10; do vf_hyg_marque_p "$p" || break; sleep 0.2; done
      vf_hyg_kill KILL "$p"; wait "$p" 2>/dev/null
    fi
  fi
  for q in ${PIDS[@]+"${PIDS[@]}"}; do [ "$q" = "$p" ] || n+=("$q"); done
  PIDS=(${n[@]+"${n[@]}"}); return 0
}
vf_hyg_arreter() {
  local p
  if vf_hyg_tag_ok; then
    for p in ${PIDS[@]+"${PIDS[@]}"}; do vf_hyg_marque_p "$p" && vf_hyg_kill TERM "$p"; done
    if [ -z "${VF_HYG_DRY:-}" ]; then
      for p in ${PIDS[@]+"${PIDS[@]}"}; do vf_hyg_stop "$p"; done
    fi
  fi
  PIDS=(); return 0
}
vf_hyg_assert() {
  local v i; vf_hyg_arreter
  if ! vf_hyg_ps_ok; then assert_eq "H-0 — ps utilisable : le pid de la suite figure dans sa sortie (sinon aucun survivant ne serait vu)" "absent" "présent"; return 0; fi
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do v="$(vf_hyg_vivants)"; [ -z "$v" ] && break; sleep 0.2; done  # grâce bornée (3 s) : les processus fils d'un Chrome tué s'éteignent seuls
  if [ "$(printf '%s\n' "$v" | grep -c .)" -gt "$VF_HYG_MAX" ]; then assert_eq "H1 — marque trop large ($VF_HYG_TAG) : plus de $VF_HYG_MAX processus la portent, aucun kill" "$(printf '%s\n' "$v" | grep -c .)" "0"; return 0; fi
  assert_eq "H0 — aucun serveur ni Chrome de cette suite ne survit (avant : ${VF_HYG_AVANT:-0})" "${v:-aucun}" "aucun"
}
# AUDC-AM7 — en CI, l'absence de Chrome fait ÉCHOUER la suite qui en dépend, au lieu d'un saut qui sort 0 (28 suites sautaient leur moitié navigateur sans garde).
# Une suite qui dépend d'un navigateur pose CHROME (ou EKCHROME, suite Équipe) à la chaîne vide, puis le cherche : vide à la sortie = introuvable.
# Hors CI (CI vide) le saut local reste permis. Échappatoires explicites : VF_CHROME_OPTIONNEL=1, et CHAINE_SANS_NAVIGATEUR (simulation voulue de la suite chaîne-xss).
# Appelée par vf_hyg_fin, donc depuis le trap EXIT de chaque suite : le dossier de travail est supprimé ici (sauf KEEP) avant le « exit 1 », qui coupe le reste du trap.
vf_hyg_chrome_ci() {
  [ -n "${CI:-}" ] || return 0
  [ -z "${VF_CHROME_OPTIONNEL:-}" ] || return 0
  [ -z "${CHAINE_SANS_NAVIGATEUR:-}" ] || return 0
  local v
  for v in CHROME EKCHROME; do
    if eval "[ \"\${$v+set}\" = set ] && [ -z \"\${$v}\" ]"; then
      echo "  ❌ FAIL — AM7 aucun navigateur (Chrome, Chromium) en CI : la moitié navigateur de cette suite n'a pas été jouée et ne peut pas sortir 0 (installer Chrome sur le poste de CI, ou CHROME_BIN)" >&2
      [ -n "${KEEP:-}" ] || { [ -n "${WORK:-}" ] && rm -rf "$WORK"; }
      exit 1
    fi
  done
  return 0
}
vf_hyg_fin() {
  local v n i; vf_hyg_tag_ok || return 0
  vf_hyg_arreter
  if ! vf_hyg_ps_ok; then echo "  ❌ FAIL — H-0 ps inutilisable : survivants invisibles, rien n'est tué" >&2; return 0; fi
  for i in 1 2 3 4; do
    v="$(vf_hyg_vivants | awk '{print $1}')"; [ -n "$v" ] || break
    n="$(printf '%s\n' "$v" | wc -l | tr -d ' ')"
    if [ "$n" -gt "$VF_HYG_MAX" ]; then echo "  ❌ FAIL — H1 marque trop large : $n processus portent la marque [$VF_HYG_TAG] (plafond $VF_HYG_MAX) — aucun kill, fuite à nettoyer à la main" >&2; return 0; fi
    # shellcheck disable=SC2086
    vf_hyg_kill $([ "$i" -lt 3 ] && echo TERM || echo KILL) $v; sleep 0.3
  done
  [ -n "${VF_HYG_DRY:-}" ] || rm -rf "${TMPDIR:-/tmp}/cdp-chrome-$VF_HYG_TAG-"* 2>/dev/null
  vf_hyg_chrome_ci
  return 0
}
