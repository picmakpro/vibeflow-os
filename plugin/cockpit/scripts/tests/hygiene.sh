# hygiene.sh — hygiène des processus des suites du cockpit (P67-G1). À « sourcer » APRÈS la définition de WORK (et du trap EXIT qui appelle vf_hyg_fin).
# Contrat : une suite arrête TOUT ce qu'elle lance, et ROUGIT si quelque chose survit. La marque d'une suite est le nom de base de son
# dossier temporaire (mktemp -d : « tmp.<alphanumérique> »), unique à chaque exécution : elle figure dans la ligne de commande de ses serveurs
# (chemin absolu du lab) et de ses Chrome (profil « cdp-chrome-<marque>- », cf. chrome-session.mjs). Aucun compte global de la machine.
# GARDE-FOUS (incident du 2026-11-02 : une marque vide faisait passer tout processus de la machine pour « de la suite », puis TERM/KILL à tous) :
#   G1 la marque atteint awk par son environnement (ps | VF_T=… awk), jamais par un préfixe qui ne vise que ps
#   G2 marque validée avant tout usage (tmp. + ≥ 6 alphanumériques, ≥ 8 caractères) — sinon FAIL nommé, et plus rien n'est listé ni tué
#   G3 plafond anti-massacre : plus de VF_HYG_MAX (20) processus marqués → aucun kill, FAIL « marque trop large »
#   G4 jamais $$, $PPID, BASHPID ni un ancêtre du shell de la suite, jamais pid ≤ 1
#   G5 VF_HYG_DRY=1 : afficher ce qui serait tué, ne rien tuer
#   vf_hyg_init      valide et pose la marque, exporte VF_CDP_TAG, arme les signaux, compte « avant » (+ fuite injectée VF_TEST_INJECTER_FUITE=1|chrome)
#   vf_hyg_vivants   liste « pid args » des processus vivants portant la marque (hors la suite et ses ancêtres)
#   vf_hyg_arreter   arrête les PID inscrits dans PIDS (attente bornée)
#   vf_hyg_assert    arrête les inscrits puis assert_eq : plus rien ne survit — un survivant est une fuite (nommé : pid et commande)
#   vf_hyg_fin       filet du trap EXIT : tue tout ce qui porte la marque (TERM puis KILL), jamais autre chose
VF_HYG_MAX=20
vf_hyg_tag_ok() { local t="${VF_HYG_TAG:-}"; [ "${#t}" -ge 8 ] && printf '%s' "$t" | grep -Eq '^tmp\.[A-Za-z0-9]{6,}$'; }
vf_hyg_init() {
  VF_HYG_TAG="$(basename "${WORK:-}")"
  if ! vf_hyg_tag_ok; then echo "  ❌ FAIL — H-1 marque de suite invalide [${VF_HYG_TAG}] (attendu : tmp.<6+ alphanumériques>) — rien n'est lancé ni tué" >&2; VF_HYG_TAG=""; exit 1; fi
  export VF_CDP_TAG="$VF_HYG_TAG"
  trap 'exit 130' INT; trap 'exit 143' TERM
  VF_HYG_AVANT="$(vf_hyg_vivants | wc -l | tr -d ' ')"
  case "${VF_TEST_INJECTER_FUITE:-}" in
    1) mkdir -p "$WORK/fuite"; echo 'setInterval(() => {}, 1000)' > "$WORK/fuite/serve.mjs"; node "$WORK/fuite/serve.mjs" >/dev/null 2>&1 </dev/null & ;;
    chrome) [ -n "${CHROME:-}" ] && { "$CHROME" --headless=new --no-sandbox --disable-gpu --no-first-run --user-data-dir="${TMPDIR:-/tmp}/cdp-chrome-$VF_HYG_TAG-fuite" about:blank >/dev/null 2>&1 </dev/null & } ;;
  esac
  return 0
}
# ancêtres du shell courant (pid, ppid, …), un par ligne
vf_hyg_ancetres() { ps -eo pid,ppid | VF_ME="$$" VF_PP="$PPID" VF_B="${BASHPID:-$$}" awk 'NR>1{pp[$1]=$2} END{n=split(ENVIRON["VF_ME"] " " ENVIRON["VF_PP"] " " ENVIRON["VF_B"],s," "); for(i=1;i<=n;i++){p=s[i]; k=0; while(p+0>1 && k<64){print p; p=pp[p]; k++}}}'; }
vf_hyg_vivants() {
  vf_hyg_tag_ok || return 0
  ps -eo pid,ppid,args | VF_T="$VF_HYG_TAG" VF_ME="$$" VF_PP="$PPID" VF_B="${BASHPID:-$$}" awk '
    BEGIN { t = ENVIRON["VF_T"]; if (length(t) < 8) exit }
    NR > 1 { pid[NR] = $1; pp[$1] = $2; a = $0; sub(/^ *[0-9]+ +[0-9]+ +/, "", a); arg[NR] = a }
    END {
      n = split(ENVIRON["VF_ME"] " " ENVIRON["VF_PP"] " " ENVIRON["VF_B"], s, " ")
      for (i = 1; i <= n; i++) { p = s[i]; k = 0; while (p + 0 > 1 && k < 64) { prot[p] = 1; p = pp[p]; k++ } }
      for (r = 2; r <= NR; r++) if ((r in pid) && !(pid[r] in prot) && index(arg[r], t) > 0) print pid[r] " " arg[r]
    }'
}
# vf_hyg_kill <signal> <pid>... : refuse pid ≤ 1, soi-même, le parent et les ancêtres ; VF_HYG_DRY=1 n'envoie rien
vf_hyg_kill() {
  local sig="$1" p anc; shift; anc=" $(vf_hyg_ancetres | tr '\n' ' ') "
  for p in "$@"; do
    case "$p" in ''|*[!0-9]*) continue ;; esac
    [ "$p" -gt 1 ] || continue
    case "$anc" in *" $p "*) continue ;; esac
    if [ -n "${VF_HYG_DRY:-}" ]; then echo "DRY kill -$sig $p"; continue; fi
    kill -"$sig" "$p" 2>/dev/null
  done
  return 0
}
vf_hyg_arreter() {
  local p i
  if vf_hyg_tag_ok; then
    for p in ${PIDS[@]+"${PIDS[@]}"}; do vf_hyg_kill TERM "$p"; done
    if [ -z "${VF_HYG_DRY:-}" ]; then
      for p in ${PIDS[@]+"${PIDS[@]}"}; do for i in 1 2 3 4 5 6 7 8 9 10; do kill -0 "$p" 2>/dev/null || break; sleep 0.2; done; vf_hyg_kill KILL "$p"; wait "$p" 2>/dev/null; done
    fi
  fi
  PIDS=(); return 0
}
vf_hyg_assert() {
  local v i; vf_hyg_arreter
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do v="$(vf_hyg_vivants)"; [ -z "$v" ] && break; sleep 0.2; done  # grâce bornée (3 s) : les processus fils d'un Chrome tué s'éteignent seuls
  assert_eq "H0 — aucun serveur ni Chrome de cette suite ne survit (avant : ${VF_HYG_AVANT:-0})" "${v:-aucun}" "aucun"
}
vf_hyg_fin() {
  local v n i; vf_hyg_tag_ok || return 0
  vf_hyg_arreter
  for i in 1 2 3 4; do
    v="$(vf_hyg_vivants | awk '{print $1}')"; [ -n "$v" ] || break
    n="$(printf '%s\n' "$v" | wc -l | tr -d ' ')"
    if [ "$n" -gt "$VF_HYG_MAX" ]; then echo "  ❌ FAIL — H1 marque trop large : $n processus portent la marque [$VF_HYG_TAG] (plafond $VF_HYG_MAX) — aucun kill" >&2; return 0; fi
    # shellcheck disable=SC2086
    vf_hyg_kill $([ "$i" -lt 3 ] && echo TERM || echo KILL) $v; sleep 0.3
  done
  [ -n "${VF_HYG_DRY:-}" ] || rm -rf "${TMPDIR:-/tmp}/cdp-chrome-$VF_HYG_TAG-"* 2>/dev/null
  return 0
}
