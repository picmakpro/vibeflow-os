#!/usr/bin/env bash
# test-check-state-integrity.sh — Suite de vérification de check-state-integrity.sh (Phase 21-04).
#
# Un cas par comportement du contrat (cf. en-tête du script). Fixtures isolées via mktemp -d +
# --path + git init, jamais sur le repo réel. Les cas 5/5b et 10/10b prouvent la DISCRIMINATION
# machine par comparaison directe de deux exécutions (même patron que test-check-mission-invariants
# cas 5b) — pas seulement "ça sort le bon code sur ce fichier-ci", mais "retirer le garde-fou change
# le verdict". Chaque assertion capture stdout/stderr ET le code de retour séparément.

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-state-integrity.sh"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mk_git_root() { # <name> -> imprime le chemin
  local d="$TMP/$1"
  mkdir -p "$d"
  git -C "$d" init -q -b main >/dev/null 2>&1 || git -C "$d" init -q >/dev/null 2>&1
  printf '%s' "$d"
}

# Écrit .planning/STATE.md avec les champs donnés puis committe. <extra-body> est ajouté après la
# section "Phase:" par défaut (permet d'injecter 0, 1 ou plusieurs lignes ^Phase:).
write_state() { # <dir> <milestone> <current_phase> <total_phases> <completed_phases> <total_plans> <completed_plans> <phase-body>
  local d="$1" ms="$2" cp="$3" tp="$4" cph="$5" tpl="$6" cpl="$7" body="$8"
  mkdir -p "$d/.planning"
  {
    printf -- '---\n'
    printf 'gsd_state_version: 1.0\n'
    printf 'milestone: %s\n' "$ms"
    printf 'current_phase: %s\n' "$cp"
    printf 'progress:\n'
    printf '  total_phases: %s\n' "$tp"
    printf '  completed_phases: %s\n' "$cph"
    printf '  total_plans: %s\n' "$tpl"
    printf '  completed_plans: %s\n' "$cpl"
    printf -- '---\n\n'
    printf '# Project State\n\n'
    printf '%s\n' "$body"
  } > "$d/.planning/STATE.md"
  git -C "$d" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t commit -q -m state >/dev/null 2>&1
}

echo "== test-check-state-integrity =="

# === Cas 1 — aucune régression (compteurs identiques) → exit 0 =====================================
D="$(mk_git_root c1)"
write_state "$D" "m1" 20 22 12 54 39 "Phase: 20 complète"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 0 ]; then ok "1 compteurs identiques → exit 0"; else ko "1 compteurs identiques → exit 0" "rc=$rc out=[$out]"; fi

# === Cas 2 — compteurs qui progressent (working tree en avance sur HEAD) → exit 0 ===================
D="$(mk_git_root c2)"
write_state "$D" "m1" 20 22 12 54 39 "Phase: 20 complète"
sed -i.bak -E 's/current_phase: 20/current_phase: 21/; s/completed_phases: 12/completed_phases: 13/; s/completed_plans: 39/completed_plans: 41/' "$D/.planning/STATE.md"
sed -i.bak2 's/Phase: 20 complète/Phase: 21 en cours/' "$D/.planning/STATE.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 0 ]; then ok "2 compteurs en progrès (working tree > HEAD) → exit 0"; else ko "2 compteurs en progrès → exit 0" "rc=$rc out=[$out]"; fi

# === Cas 3 — current_phase régresse seul → exit 1, message nomme le champ ===========================
D="$(mk_git_root c3)"
write_state "$D" "m1" 20 22 12 54 39 "Phase: 20 complète"
sed -i.bak 's/current_phase: 20/current_phase: 19/' "$D/.planning/STATE.md"
err="$(bash "$SCRIPT" --path "$D" 2>&1 >/dev/null)"; rc=$?
named=0; case "$err" in *"RÉGRESSION current_phase"*) named=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$named" -eq 1 ]; then ok "3 current_phase régresse → exit 1, champ nommé"; else ko "3 current_phase régresse → exit 1, champ nommé" "rc=$rc err=[$err]"; fi

# === Cas 4 — completed_phases régresse seul (motif exact de l'incident du 2026-07-31) → exit 1 =====
D="$(mk_git_root c4)"
write_state "$D" "gsd-migration" 20 22 12 54 39 "Phase: 20 complète"
sed -i.bak 's/completed_phases: 12/completed_phases: 10/' "$D/.planning/STATE.md"
err="$(bash "$SCRIPT" --path "$D" 2>&1 >/dev/null)"; rc=$?
named=0; case "$err" in *"RÉGRESSION completed_phases"*"12"*"10"*) named=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$named" -eq 1 ]; then ok "4 completed_phases régresse (motif de l'incident réel) → exit 1"; else ko "4 completed_phases régresse → exit 1" "rc=$rc err=[$err]"; fi

# === Cas 4b — completed_plans régresse seul → exit 1 =================================================
D="$(mk_git_root c4b)"
write_state "$D" "m1" 20 22 12 54 39 "Phase: 20 complète"
sed -i.bak 's/completed_plans: 39/completed_plans: 29/' "$D/.planning/STATE.md"
err="$(bash "$SCRIPT" --path "$D" 2>&1 >/dev/null)"; rc=$?
named=0; case "$err" in *"RÉGRESSION completed_plans"*) named=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$named" -eq 1 ]; then ok "4b completed_plans régresse → exit 1"; else ko "4b completed_plans régresse → exit 1" "rc=$rc err=[$err]"; fi

# === Cas 4d — total_plans régresse SEUL (motif exact de l'incident réel : 53→49, correctif de revue
# 21-04 — ce champ était absent de l'invariant initial malgré sa citation dans l'en-tête du gate) ===
D="$(mk_git_root c4d)"
write_state "$D" "m1" 20 22 12 54 39 "Phase: 20 complète"
sed -i.bak 's/total_plans: 54/total_plans: 49/' "$D/.planning/STATE.md"
err="$(bash "$SCRIPT" --path "$D" 2>&1 >/dev/null)"; rc=$?
named=0; case "$err" in *"RÉGRESSION total_plans"*"54"*"49"*) named=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$named" -eq 1 ]; then ok "4d total_plans régresse seul → exit 1"; else ko "4d total_plans régresse seul → exit 1" "rc=$rc err=[$err]"; fi

# === Cas 4c — trois champs régressent ensemble → les trois sont nommés (pas juste le premier) ======
D="$(mk_git_root c4c)"
write_state "$D" "m1" 20 22 12 54 39 "Phase: 20 complète"
sed -i.bak -E 's/current_phase: 20/current_phase: 19/; s/completed_phases: 12/completed_phases: 10/; s/completed_plans: 39/completed_plans: 29/' "$D/.planning/STATE.md"
err="$(bash "$SCRIPT" --path "$D" 2>&1 >/dev/null)"; rc=$?
n1=0; case "$err" in *"current_phase"*) n1=1 ;; esac
n2=0; case "$err" in *"completed_phases"*) n2=1 ;; esac
n3=0; case "$err" in *"completed_plans"*) n3=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$n1" -eq 1 ] && [ "$n2" -eq 1 ] && [ "$n3" -eq 1 ]; then
  ok "4c triple régression → les 3 champs nommés, pas juste le premier"
else
  ko "4c triple régression → les 3 champs nommés" "rc=$rc n1=$n1 n2=$n2 n3=$n3 err=[$err]"
fi

# === Cas 5 — garde de jalon : DISCRIMINATION MACHINE (même régression brute, verdict différent selon
# que le jalon a changé ou non). Preuve directe façon cas 5b de test-check-mission-invariants.sh :
# rc_meme_jalon DOIT différer de rc_jalon_different pour la même baisse de compteur. -----------------
D_SAME="$(mk_git_root c5-same)"
write_state "$D_SAME" "gsd-migration" 20 22 12 54 39 "Phase: 20 complète"
sed -i.bak 's/completed_phases: 12/completed_phases: 10/' "$D_SAME/.planning/STATE.md"
rc_same=$(bash "$SCRIPT" --path "$D_SAME" >/dev/null 2>&1; echo $?)

D_DIFF="$(mk_git_root c5-diff)"
write_state "$D_DIFF" "gsd-migration" 20 22 12 54 39 "Phase: 20 complète"
sed -i.bak -E 's/milestone: gsd-migration/milestone: vf-routing-2/; s/completed_phases: 12/completed_phases: 10/; s/current_phase: 20/current_phase: 1/; s/total_phases: 22/total_phases: 3/' "$D_DIFF/.planning/STATE.md"
rc_diff=$(bash "$SCRIPT" --path "$D_DIFF" >/dev/null 2>&1; echo $?)

if [ "$rc_same" -eq 1 ] && [ "$rc_diff" -eq 0 ] && [ "$rc_same" -ne "$rc_diff" ]; then
  ok "5 discrimination machine — garde de jalon : rc(même jalon)=$rc_same != rc(jalon changé)=$rc_diff"
else
  ko "5 discrimination machine — garde de jalon" "rc_same=$rc_same rc_diff=$rc_diff (devrait être 1 et 0)"
fi

# === Cas 5c — `milestone:` illisible d'UN SEUL côté (courant) alors que le fichier régresse par
# ailleurs → exit 2 (intégrité compromise), JAMAIS un skip silencieux façon "jalon différent".
# Correctif de revue (plan 21-04) : avant ce correctif, ce cas rendait exit 0 (skip), exactement le
# trou qu'une corruption qui casse à la fois les compteurs ET la ligne milestone aurait exploité. ===
D="$(mk_git_root c5c)"
write_state "$D" "gsd-migration" 20 22 12 54 39 "Phase: 20 complète"
sed -i.bak -E '/^milestone: gsd-migration$/d; s/completed_phases: 12/completed_phases: 2/' "$D/.planning/STATE.md"
err="$(bash "$SCRIPT" --path "$D" 2>&1 >/dev/null)"; rc=$?
if [ "$rc" -eq 2 ]; then
  ok "5c milestone illisible d'un seul côté + régression réelle → exit 2 (jamais un skip)"
else
  ko "5c milestone illisible d'un seul côté → exit 2" "rc=$rc err=[$err]"
fi

# === Cas 6 — aucune baseline à --against (fichier tout juste créé) → exit 0, pas une erreur =========
D="$(mk_git_root c6)"
write_state "$D" "m1" 1 1 0 1 0 "Phase: 1 en cours"
out="$(bash "$SCRIPT" --path "$D" --against 'HEAD~5' 2>&1)"; rc=$?
# HEAD~5 n'existe pas (un seul commit) → doit être traité comme ref invalide (cas 6b), pas silencieux
if [ "$rc" -eq 2 ]; then ok "6 --against sur un ancêtre inexistant → exit 2 (ref invalide, pas un skip silencieux)"; else ko "6 --against ancêtre inexistant → exit 2" "rc=$rc out=[$out]"; fi

# === Cas 6b — --against une ref VALIDE mais qui ne contient pas encore le fichier → exit 0 (skip légitime)
D="$(mk_git_root c6b)"
mkdir -p "$D/empty"
: > "$D/empty/.gitkeep"
git -C "$D" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$D" -c user.email=t@t -c user.name=t commit -q -m "premier commit sans STATE.md" >/dev/null 2>&1
write_state "$D" "m1" 1 1 0 1 0 "Phase: 1 en cours"
err="$(bash "$SCRIPT" --path "$D" --against 'HEAD~1' 2>&1 >/dev/null)"; rc=$?
mentions_skip=0; case "$err" in *"rien à régresser"*) mentions_skip=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$mentions_skip" -eq 1 ]; then
  ok "6b ref valide sans le fichier (1er commit du fichier) → exit 0, skip explicite"
else
  ko "6b ref valide sans le fichier → exit 0, skip explicite" "rc=$rc err=[$err]"
fi

# === Cas 7 — --against sur une chaîne qui ne résout à aucun commit → exit 2, jamais un skip silencieux
D="$(mk_git_root c7)"
write_state "$D" "m1" 1 1 0 1 0 "Phase: 1 en cours"
err="$(bash "$SCRIPT" --path "$D" --against "n-existe-pas-du-tout" 2>&1 >/dev/null)"; rc=$?
if [ "$rc" -eq 2 ]; then ok "7 --against ref inconnue → exit 2 (usage invalide)"; else ko "7 --against ref inconnue → exit 2" "rc=$rc err=[$err]"; fi

# === Cas 8 — exactement 1 ligne ^Phase: (nominal) → cette partie du contrat ne fait pas échouer =====
D="$(mk_git_root c8)"
write_state "$D" "m1" 1 1 0 1 0 "Phase: 1 en cours, seule ligne"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 0 ]; then ok "8 exactement 1 ligne ^Phase: → conforme"; else ko "8 exactement 1 ligne ^Phase:" "rc=$rc out=[$out]"; fi

# === Cas 9 — zéro ligne ^Phase: → exit 1, invariant nommé ===========================================
D="$(mk_git_root c9)"
write_state "$D" "m1" 1 1 0 1 0 "Aucune ligne Phase ici, juste de la prose."
err="$(bash "$SCRIPT" --path "$D" 2>&1 >/dev/null)"; rc=$?
named=0; case "$err" in *"0 ligne(s) '^Phase:'"*) named=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$named" -eq 1 ]; then ok "9 zéro ligne ^Phase: → exit 1, compte nommé"; else ko "9 zéro ligne ^Phase:" "rc=$rc err=[$err]"; fi

# === Cas 10 — deux lignes ^Phase: (motif exact de la cause B réelle : archive + courante) → exit 1,
# DISCRIMINATION MACHINE par comparaison directe avec le cas à 1 ligne. ------------------------------
D1="$(mk_git_root c10-un)"
write_state "$D1" "m1" 1 1 0 1 0 "Phase: 1 en cours"
rc_un=$(bash "$SCRIPT" --path "$D1" >/dev/null 2>&1; echo $?)

D2="$(mk_git_root c10-deux)"
write_state "$D2" "m1" 1 1 0 1 0 "Phase: 1 en cours

---

Phase: 0 archive (forme non conforme, reproduit la cause B réelle)"
rc_deux=$(bash "$SCRIPT" --path "$D2" >/dev/null 2>&1; echo $?)

if [ "$rc_un" -eq 0 ] && [ "$rc_deux" -eq 1 ] && [ "$rc_un" -ne "$rc_deux" ]; then
  ok "10 discrimination machine — 1 ligne (rc=$rc_un) != 2 lignes, motif cause B réelle (rc=$rc_deux)"
else
  ko "10 discrimination machine — 1 vs 2 lignes ^Phase:" "rc_un=$rc_un rc_deux=$rc_deux"
fi

# === Cas 10b — la forme d'archivage ADR-063 ("**Phase archivée :**") NE matche PAS ^Phase: ==========
D="$(mk_git_root c10b)"
write_state "$D" "m1" 21 22 12 55 40 "Phase: 21 en cours

---

**Phase archivée :** 19 complète — vérifiée et shippée."
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 0 ]; then ok "10b forme d'archivage ADR-063 ne casse pas l'invariant → exit 0"; else ko "10b forme d'archivage ADR-063" "rc=$rc out=[$out]"; fi

# === Cas 11 — --current-ref compare deux refs entre elles (pas le fichier de travail) ===============
D="$(mk_git_root c11)"
write_state "$D" "m1" 20 22 12 54 39 "Phase: 20 complète"
FIRST_SHA="$(git -C "$D" rev-parse HEAD)"
sed -i.bak 's/completed_phases: 12/completed_phases: 10/' "$D/.planning/STATE.md"
git -C "$D" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$D" -c user.email=t@t -c user.name=t commit -q -m "regression committee" >/dev/null 2>&1
err="$(bash "$SCRIPT" --path "$D" --current-ref HEAD --against "$FIRST_SHA" 2>&1 >/dev/null)"; rc=$?
named=0; case "$err" in *"RÉGRESSION completed_phases"*) named=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$named" -eq 1 ]; then
  ok "11 --current-ref HEAD vs --against <sha antérieur> détecte la régression commitée"
else
  ko "11 --current-ref vs --against (deux refs)" "rc=$rc err=[$err]"
fi

# === Cas 12 — hors d'un dépôt git → exit 2 ============================================================
D="$TMP/not-a-repo"; mkdir -p "$D/.planning"
printf -- '---\nmilestone: m1\ncurrent_phase: 1\nprogress:\n  total_phases: 1\n  completed_phases: 0\n  total_plans: 1\n  completed_plans: 0\n---\n\nPhase: 1\n' > "$D/.planning/STATE.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 2 ]; then ok "12 hors d'un dépôt git → exit 2"; else ko "12 hors d'un dépôt git → exit 2" "rc=$rc out=[$out]"; fi

# === Cas 13 — fichier introuvable au chemin par défaut → exit 2 ======================================
D="$(mk_git_root c13)"
: > "$D/.gitkeep"
git -C "$D" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$D" -c user.email=t@t -c user.name=t commit -q -m "vide" >/dev/null 2>&1
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 2 ]; then ok "13 fichier introuvable → exit 2"; else ko "13 fichier introuvable → exit 2" "rc=$rc out=[$out]"; fi

# === Cas 14 — usage : arguments =======================================================================
bash "$SCRIPT" --nope >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "14 argument inconnu → exit 64"; else ko "14 argument inconnu → exit 64" "rc=$rc"; fi

bash "$SCRIPT" --path >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "14b --path sans valeur → exit 64"; else ko "14b --path sans valeur → exit 64" "rc=$rc"; fi

bash "$SCRIPT" --against >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "14c --against sans valeur → exit 64"; else ko "14c --against sans valeur → exit 64" "rc=$rc"; fi

out="$(bash "$SCRIPT" --help 2>/dev/null)"; rc=$?
if [ "$rc" -eq 0 ] && [ -n "$out" ]; then ok "14d --help → exit 0, sortie non vide"; else ko "14d --help → exit 0, sortie non vide" "rc=$rc"; fi

# === Cas 15 — lecture seule : empreinte du dépôt identique avant/après (.git compris) ================
D="$(mk_git_root c15)"
write_state "$D" "m1" 20 22 12 54 39 "Phase: 20 complète"
before="$(find "$D" | LC_ALL=C sort)"
bash "$SCRIPT" --path "$D" >/dev/null 2>&1
after="$(find "$D" | LC_ALL=C sort)"
if [ "$before" = "$after" ]; then ok "15 lecture seule — empreinte find identique avant/après"; else ko "15 lecture seule" "before=[$before] after=[$after]"; fi

# ======================================================================================================
# Workstreams GSD (GSDA-13) — le défaut de --file suit le compartiment actif ; --file prime toujours.
# ======================================================================================================

# Écrit un STATE.md dans .planning/workstreams/<ws>/ puis committe. Même forme que write_state.
write_ws_state() { # <dir> <ws> <milestone> <cp> <tp> <cph> <tpl> <cpl> <phase-body>
  local d="$1" ws="$2" ms="$3" cp="$4" tp="$5" cph="$6" tpl="$7" cpl="$8" body="$9"
  mkdir -p "$d/.planning/workstreams/$ws"
  {
    printf -- '---\n'
    printf 'gsd_state_version: 1.0\n'
    printf 'milestone: %s\n' "$ms"
    printf 'current_phase: %s\n' "$cp"
    printf 'progress:\n'
    printf '  total_phases: %s\n' "$tp"
    printf '  completed_phases: %s\n' "$cph"
    printf '  total_plans: %s\n' "$tpl"
    printf '  completed_plans: %s\n' "$cpl"
    printf -- '---\n\n'
    printf '# Project State\n\n'
    printf '%s\n' "$body"
  } > "$d/.planning/workstreams/$ws/STATE.md"
  git -C "$d" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t commit -q -m ws-state >/dev/null 2>&1
}

# === Cas 17 — NON-RÉGRESSION : dépôt non partitionné, aucune variable → verdict inchangé =============
D="$(mk_git_root c17)"
write_state "$D" "m1" 20 22 12 54 39 "Phase: 20 complète"
out="$(env -u GSD_WORKSTREAM -u VF_STATE_WORKSTREAM bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
names_root=0; case "$out" in *".planning/STATE.md conforme"*) names_root=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$names_root" -eq 1 ]; then
  ok "17 non-régression — dépôt non partitionné, aucune variable → exit 0 sur .planning/STATE.md"
else
  ko "17 non-régression dépôt non partitionné" "rc=$rc out=[$out]"
fi

# === Cas 17b — NON-RÉGRESSION DURE : la garde ADR-063 reste AUSSI stricte sans workstream ============
# Le cas nominal ne doit RIEN perdre : deux lignes ^Phase: dans un arbre non partitionné, sans
# aucune variable posée, restent un exit 1. C'est la garantie que Samuel utilise à chaque clôture.
D="$(mk_git_root c17b)"
write_state "$D" "m1" 20 22 12 54 39 "Phase: 20 complète

---

Phase: 19 archive non conforme"
rc_deuxlignes=$(env -u GSD_WORKSTREAM -u VF_STATE_WORKSTREAM bash "$SCRIPT" --path "$D" >/dev/null 2>&1; echo $?)
D2="$(mk_git_root c17b-reg)"
write_state "$D2" "m1" 20 22 12 54 39 "Phase: 20 complète"
sed -i.bak 's/completed_phases: 12/completed_phases: 10/' "$D2/.planning/STATE.md"
rc_regress=$(env -u GSD_WORKSTREAM -u VF_STATE_WORKSTREAM bash "$SCRIPT" --path "$D2" >/dev/null 2>&1; echo $?)
if [ "$rc_deuxlignes" -eq 1 ] && [ "$rc_regress" -eq 1 ]; then
  ok "17b non-régression dure — sans workstream, ADR-063 (rc=$rc_deuxlignes) et anti-régression (rc=$rc_regress) restent armés"
else
  ko "17b non-régression dure des deux invariants" "rc_deuxlignes=$rc_deuxlignes rc_regress=$rc_regress (attendus 1 et 1)"
fi

# === Cas 18 — GSD_WORKSTREAM : le défaut résout vers le STATE.md du compartiment =====================
D="$(mk_git_root c18)"
write_state "$D" "m1" 20 22 12 54 39 "Phase: 20 complète"
write_ws_state "$D" "dev" "m1" 3 5 2 9 6 "Phase: 3 en cours"
out="$(GSD_WORKSTREAM=dev bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
names_ws=0; case "$out" in *".planning/workstreams/dev/STATE.md conforme"*) names_ws=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$names_ws" -eq 1 ]; then
  ok "18 GSD_WORKSTREAM=dev → exit 0, le message de conformité désigne le STATE.md du compartiment"
else
  ko "18 GSD_WORKSTREAM=dev → STATE.md du compartiment" "rc=$rc out=[$out]"
fi

# === Cas 18b — DISCRIMINATION MACHINE : le compartiment est bien le fichier VÉRIFIÉ ==================
# Le compartiment régresse, la racine non. Sans résolution, le gate serait vert ; avec elle, rouge.
D="$(mk_git_root c18b)"
write_state "$D" "m1" 20 22 12 54 39 "Phase: 20 complète"
write_ws_state "$D" "dev" "m1" 3 5 2 9 6 "Phase: 3 en cours"
sed -i.bak 's/completed_plans: 6/completed_plans: 1/' "$D/.planning/workstreams/dev/STATE.md"
rc_sans=$(env -u GSD_WORKSTREAM -u VF_STATE_WORKSTREAM bash "$SCRIPT" --path "$D" >/dev/null 2>&1; echo $?)
err_avec="$(GSD_WORKSTREAM=dev bash "$SCRIPT" --path "$D" 2>&1 >/dev/null)"; rc_avec=$?
named=0; case "$err_avec" in *"RÉGRESSION completed_plans"*) named=1 ;; esac
if [ "$rc_sans" -eq 0 ] && [ "$rc_avec" -eq 1 ] && [ "$named" -eq 1 ]; then
  ok "18b discrimination machine — régression DANS le compartiment : rc(sans ws)=$rc_sans != rc(avec ws)=$rc_avec"
else
  ko "18b discrimination machine compartiment" "rc_sans=$rc_sans rc_avec=$rc_avec err=[$err_avec]"
fi

# === Cas 19 — `--file` EXPLICITE prime sur la résolution automatique =================================
# Même dépôt que 18b : le compartiment régresse, la racine est saine. Un --file sur la racine doit
# donc rendre 0 MALGRÉ GSD_WORKSTREAM=dev — preuve que la résolution n'a pas écrasé la surcharge.
out="$(GSD_WORKSTREAM=dev bash "$SCRIPT" --path "$D" --file .planning/STATE.md 2>/dev/null)"; rc=$?
names_root=0; case "$out" in *".planning/STATE.md conforme"*) names_root=1 ;; esac
leaks_ws=0; case "$out" in *"workstreams"*) leaks_ws=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$names_root" -eq 1 ] && [ "$leaks_ws" -eq 0 ]; then
  ok "19 --file explicite prime — fichier comparé = celui de --file, jamais celui du workstream"
else
  ko "19 --file explicite prime sur la résolution" "rc=$rc out=[$out]"
fi

# === Cas 19b — `--file` explicite prime AUSSI vers le compartiment (surcharge dans les deux sens) ====
out="$(env -u GSD_WORKSTREAM -u VF_STATE_WORKSTREAM bash "$SCRIPT" --path "$D" --file .planning/workstreams/dev/STATE.md 2>&1 >/dev/null)"; rc=$?
if [ "$rc" -eq 1 ]; then
  ok "19b --file vers le compartiment, sans variable → la régression du compartiment est vue (exit 1)"
else
  ko "19b --file vers le compartiment" "rc=$rc out=[$out]"
fi

# === Cas 20 — Workstream nommé, dossier ABSENT → exit 2 + stderr qui NOMME le workstream =============
# Fail-closed : jamais un repli silencieux sur la racine, qui rendrait « conforme » sur un fichier
# que l'appelant ne croyait pas vérifier.
D="$(mk_git_root c20)"
write_state "$D" "m1" 20 22 12 54 39 "Phase: 20 complète"
err="$(GSD_WORKSTREAM=inexistant bash "$SCRIPT" --path "$D" 2>&1 >/dev/null)"; rc=$?
named=0; case "$err" in *"inexistant"*) named=1 ;; esac
if [ "$rc" -eq 2 ] && [ "$named" -eq 1 ]; then
  ok "20 workstream nommé sans dossier → exit 2, stderr cite « inexistant » (jamais un repli racine)"
else
  ko "20 workstream sans dossier → exit 2 + nom" "rc=$rc err=[$err]"
fi

# === Cas 20b — DISCRIMINATION : le repli racine aurait rendu 0, le fail-closed rend 2 ================
rc_racine=$(env -u GSD_WORKSTREAM -u VF_STATE_WORKSTREAM bash "$SCRIPT" --path "$D" >/dev/null 2>&1; echo $?)
rc_absent=$(GSD_WORKSTREAM=inexistant bash "$SCRIPT" --path "$D" >/dev/null 2>&1; echo $?)
if [ "$rc_racine" -eq 0 ] && [ "$rc_absent" -eq 2 ]; then
  ok "20c discrimination — même dépôt : rc(racine)=$rc_racine, rc(ws introuvable)=$rc_absent"
else
  ko "20c discrimination repli vs fail-closed" "rc_racine=$rc_racine rc_absent=$rc_absent"
fi

# === Cas 21 — Pointeur partagé in-repo, et précédence VF_STATE_WORKSTREAM ============================
D="$(mk_git_root c21)"
write_state "$D" "m1" 20 22 12 54 39 "Phase: 20 complète"
write_ws_state "$D" "dev" "m1" 3 5 2 9 6 "Phase: 3 en cours"
printf 'dev\n' > "$D/.planning/active-workstream"
out="$(env -u GSD_WORKSTREAM -u VF_STATE_WORKSTREAM bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
names_ws=0; case "$out" in *"workstreams/dev/STATE.md conforme"*) names_ws=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$names_ws" -eq 1 ]; then
  ok "21 pointeur partagé .planning/active-workstream → même résolution que GSD_WORKSTREAM"
else
  ko "21 pointeur partagé" "rc=$rc out=[$out]"
fi
# La surcharge de test prime sur les deux autres canaux : elle nomme un dossier absent → exit 2.
err="$(VF_STATE_WORKSTREAM=surcharge GSD_WORKSTREAM=dev bash "$SCRIPT" --path "$D" 2>&1 >/dev/null)"; rc=$?
named=0; case "$err" in *"surcharge"*) named=1 ;; esac
if [ "$rc" -eq 2 ] && [ "$named" -eq 1 ]; then
  ok "21b précédence — VF_STATE_WORKSTREAM prime sur GSD_WORKSTREAM et sur le pointeur"
else
  ko "21b précédence VF_STATE_WORKSTREAM" "rc=$rc err=[$err]"
fi

# === Cas 22 — Nom hors politique : « aucun workstream », JAMAIS concaténé ============================
# Le compartiment `dev` du dépôt c21 régresserait s'il était atteint : un nom qui s'évaderait vers lui
# rendrait 1. Le fail-closed du cas 20 rendrait 2. Le seul verdict admissible est 0 sur la racine.
D="$(mk_git_root c22)"
write_state "$D" "m1" 20 22 12 54 39 "Phase: 20 complète"
write_ws_state "$D" "dev" "m1" 3 5 2 9 6 "Phase: 3 en cours"
sed -i.bak 's/completed_plans: 6/completed_plans: 1/' "$D/.planning/workstreams/dev/STATE.md"
bad_all_ok=1
for bad in '../workstreams/dev' '..' '.' 'a/b' 'a b' '-lead' 'x;y'; do
  o="$(GSD_WORKSTREAM="$bad" bash "$SCRIPT" --path "$D" 2>&1)"; r=$?
  case "$o" in *"workstreams/$bad"*) bad_all_ok=0 ;; esac
  [ "$r" -eq 0 ] || bad_all_ok=0
done
if [ "$bad_all_ok" -eq 1 ]; then
  ok "22 noms hors politique (7 formes, dont ../workstreams/dev résolvable) → exit 0 sur la racine"
else
  ko "22 noms hors politique → aucune concaténation" "un nom a fui ou changé le verdict"
fi

# === Cas 23 — Contrat de sortie : aucun code hors {0, 1, 2, 64} =======================================
codes_ok=1
for e in "GSD_WORKSTREAM=dev" "GSD_WORKSTREAM=inexistant" "GSD_WORKSTREAM=../workstreams/dev" "VF_STATE_WORKSTREAM=dev"; do
  r=$(env "$e" bash "$SCRIPT" --path "$D" >/dev/null 2>&1; echo $?)
  case "$r" in 0|1|2|64) : ;; *) codes_ok=0 ;; esac
done
if [ "$codes_ok" -eq 1 ]; then ok "23 contrat de sortie inchangé — aucun code hors {0, 1, 2, 64}"; else ko "23 contrat de sortie {0,1,2,64}" "code hors contrat"; fi

# === Cas 16 — bash -n passe sur le script (syntaxe) ===================================================
if bash -n "$SCRIPT" 2>/dev/null; then ok "16 bash -n passe sur check-state-integrity.sh"; else ko "16 bash -n passe" "syntax error"; fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
