# chrome-saut.sh — l'UNIQUE mécanisme « pas de Chrome » des suites du cockpit (AUDC-AM7). À sourcer, sans condition : aucune dépendance (ni WORK ni hygiene.sh).
#   vf_chrome_saut "<message du saut>"   à appeler AU POINT du saut, à la place de l'écho seul : écrit le message (stdout) puis, en CI, échoue sur place
#                                        (exit 1, message AM7 sur stderr) ; hors CI rend 0 et la suite poursuit son saut (le saut local reste permis).
#   vf_chrome_ci_exige                   vrai (0) quand l'absence de Chrome doit échouer : CI posé, et ni VF_CHROME_OPTIONNEL ni une simulation voulue
#                                        (CHAINE_SANS_NAVIGATEUR, SIGNAL_SANS_NAVIGATEUR) ; lu aussi par le filet de sortie de hygiene.sh (vf_hyg_chrome_ci).
vf_chrome_ci_exige() {
  [ -n "${CI:-}" ] || return 1
  [ -z "${VF_CHROME_OPTIONNEL:-}" ] || return 1
  [ -z "${CHAINE_SANS_NAVIGATEUR:-}" ] || return 1
  [ -z "${SIGNAL_SANS_NAVIGATEUR:-}" ] || return 1
  return 0
}
vf_chrome_saut() {
  echo "$1"
  if vf_chrome_ci_exige; then
    echo "  ❌ FAIL — AM7 aucun navigateur (Chrome, Chromium) en CI : la moitié navigateur de cette suite n'est pas jouée et ne peut pas sortir 0 (installer Chrome sur le poste de CI, ou CHROME_BIN)" >&2
    exit 1
  fi
  return 0
}
