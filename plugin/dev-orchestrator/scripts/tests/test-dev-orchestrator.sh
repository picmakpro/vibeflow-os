#!/usr/bin/env bash
# test-dev-orchestrator.sh — Suite de vérification du module dev-orchestrator (VFDO)
#
# Couvre les 4 axes imposés par la spec §8 (VERIF-01) + les gates de densité (VERIF-02) :
#   T1 — build-gsd-index.sh génère un index NON VIDE depuis les skills GSD installés
#        (SKIP explicite si aucun skill gsd-* présent sur la machine).
#   T2 — ensure-deps.sh idempotent (2 runs en dry-run = no-op, exit 0 aux deux).
#   T3 — La table de routage de AGENT.md couvre ≥11 intentions :
#        (a) ≥11 VERBES /vf-* DISTINCTS, (b) ≥11 lignes d'intentions NL dans la table.
#        /!\ Changement de sémantique (étape 12, D-09) : (a) comptait auparavant les cibles
#        gsd-* canoniques citées dans l'agent. VERB-01 interdit désormais toute cible gsd-*
#        dans la table — l'agent route vers un VERBE, le verbe connaît sa cible. Compter des
#        cibles reviendrait à exiger le résidu que l'étape supprime ; la couverture de routage
#        est donc mesurée sur les verbes, à seuil identique (≥11). L'absence de gsd-* dans la
#        table est asserte par T13.
#   T4 — Chaque skill /vf-* mappe vers une cible existante (aucun orphelin) :
#        gsd-X vérifié contre gsd-skills-index.md (fixture de secours si index vide),
#        brainstorming (superpowers) et ensure-deps (bootstrap interne) acceptés.
#   T5 — Densité (VERIF-02) MESURÉE PAR wc -l UNIQUEMENT : AGENT.md ≤250L, chaque skill ≤500L.
#        (NE PAS appeler le contrôleur de taille générique qui ignore les .md.)
#   T6 — Install end-to-end via vibeflow-update.sh (best-effort, SKIP si non réalisable).
#   T7 — Garde-fou first-use présent dans AGENT.md : détection .planning + délégation vf-init
#        + new-project encadré (régression FIRST-01/FIRST-02 ; fichier filtré des commentaires).
#   T8/T8b — Équipe manager : 4 agents conformes (frontmatter, densité, vf-internal — Pattern 12).
#   T9 — Contrats de mission : source unique + 3 renvois (DRY).
#   T10 — Routage mission (AGENT.md) + aiguillage taille (vf-auto, SEUIL_EQUIPE).
#   T11 — Généricité : aucun renvoi vers un chemin absent d'un lab installé (DM5).
#   T12 — Anti-collision des descriptions de verbes (les deux modules).
#   T13 — Préséance : la rule globale existe, est conforme et est référencée.
#   T14 — Exhaustivité du routage : intent-routing.md couvre l'index, et chaque cible
#         portée par un verbe est bien citée dans le corps de ce verbe.
#
# Correspondance avec les noms de la spec de routage fin (2026-07-25) :
#   T12 (ici) = T11 (spec) · T13 (ici) = T12 (spec) · T14 (ici) = T13 (spec).
# Le T11 (ici) EXISTE DÉJÀ — généricité (DM5) — et n'est PAS renuméroté :
# renuméroter un test de non-régression ferait perdre sa trace dans l'historique. La numérotation
# locale est donc décalée d'un cran par rapport à la spec, à dessein.
#
# Convention : asserts numérotés, helpers ok()/ko()/skip(), exit 0 si tout passe
# (SKIP non bloquant), exit 1 si au moins un KO. Calqué sur le pattern de test du repo.
#
# Référence : VERIF-01, VERIF-02, IDX-02, D4, D7, VERB-01→VERB-05.

set -uo pipefail

# Résolution du module (racine = dossier parent de scripts/tests/).
MOD="$(cd "$(dirname "$0")/../.." && pwd)"
REPO="$(cd "$MOD/.." && pwd)"

# Détection de la disposition : source (dev-orchestrator/) vs lab installé (.claude/).
# - Source : AGENT.md + references/ à la racine du module.
# - Lab installé : agent à plat dans agents/dev-orchestrator.md, references sous
#   agents/dev-orchestrator-references/ (D7). skills/ et scripts/ sont identiques aux deux.
if [ -f "$MOD/AGENT.md" ]; then
  AGENT_FILE="$MOD/AGENT.md"
  REFS_DIR="$MOD/references"
elif [ -f "$MOD/agents/dev-orchestrator.md" ]; then
  AGENT_FILE="$MOD/agents/dev-orchestrator.md"
  REFS_DIR="$MOD/agents/dev-orchestrator-references"
else
  echo "  ✗ Impossible de localiser l'agent (ni source AGENT.md, ni lab agents/dev-orchestrator.md)"; exit 1
fi

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

# grep insensible à l'alias zsh (ugrep) : on force le binaire système.
GREP="$(command -v grep)"

# ---------------------------------------------------------------------------
# Périmètre : les verbes /vf-* POSSÉDÉS par ce module (+ son compagnon design)
# ---------------------------------------------------------------------------
# En lab installé, `.claude/skills/` est PLAT et PARTAGÉ par tous les modules (conductor —
# socle obligatoire —, validator, planning-core…). Auditer un verbe étranger produirait un KO chez
# l'utilisateur pour un fichier qu'on ne peut pas corriger d'ici, et vert en source : le piège n° 1
# déplacé d'un cran. La liste de propriété est la colonne « Verbe » de la doctrine de routage —
# c'est le fichier du module qui déclare ce qu'il porte, elle se met donc à jour toute seule quand
# un verbe est ajouté. (Une denylist des verbes des autres modules pourrirait au module suivant.)
ROUTING="$REFS_DIR/intent-routing.md"
OWNED_VERBS=""
if [ -f "$ROUTING" ]; then
  OWNED_VERBS=$("$GREP" -E '^\|' "$ROUTING" \
    | "$GREP" -v -E '^\|[[:space:]]*-{2,}' \
    | "$GREP" -v -iE '^\|[[:space:]]*Intention' \
    | awk -F'|' '{print $3}' \
    | "$GREP" -oE '/vf-[a-z0-9-]+' | sed 's|^/||' | sort -u | tr '\n' ' ')
fi
# Doctrine absente ou illisible : on retombe sur le comportement historique (tout auditer).
# Ce n'est pas silencieux — T14 échoue déjà bruyamment dans ce cas.
owned_verb() {
  [ -z "$OWNED_VERBS" ] && return 0
  case " $OWNED_VERBS " in *" $1 "*) return 0 ;; esac
  return 1
}

echo "== test-dev-orchestrator (module: $MOD) =="

# ---------------------------------------------------------------------------
# T1 — Index factuel non vide (ou SKIP si pas de GSD installé)
# ---------------------------------------------------------------------------
GSD_SKILLS_DIR="${VF_GSD_SKILLS_DIR:-$HOME/.claude/skills}"
gsd_installed=0
if "$GREP" -q . <(ls -d "$GSD_SKILLS_DIR"/gsd-*/SKILL.md 2>/dev/null); then
  gsd_installed=1
fi

INDEX_TMP="$(mktemp)"
trap 'rm -f "$INDEX_TMP"' EXIT

if VF_INDEX_OUT="$INDEX_TMP" bash "$MOD/scripts/build-gsd-index.sh" >/dev/null 2>&1; then
  if [ "$gsd_installed" -eq 1 ]; then
    distinct_skills=$("$GREP" -Eo 'gsd-[a-z0-9-]+' "$INDEX_TMP" | sort -u | wc -l | tr -d ' ')
    if [ "${distinct_skills:-0}" -ge 1 ]; then
      ok "T1 index : généré, non vide ($distinct_skills skill(s) gsd-* distinct(s))"
    else
      ko "T1 index : GSD présent mais aucun skill extrait de l'index"
    fi
  else
    skip "T1 index : GSD non installé — index vide attendu (pas un échec)"
  fi
else
  ko "T1 index : build-gsd-index.sh a échoué (exit non-zéro)"
fi

# ---------------------------------------------------------------------------
# T2 — ensure-deps.sh idempotent (dry-run, 2 runs, exit 0 aux deux)
# ---------------------------------------------------------------------------
VF_ENSURE_DRY_RUN=1 bash "$MOD/scripts/ensure-deps.sh" >/dev/null 2>&1
r1=$?
VF_ENSURE_DRY_RUN=1 bash "$MOD/scripts/ensure-deps.sh" >/dev/null 2>&1
r2=$?
if [ "$r1" -eq 0 ] && [ "$r2" -eq 0 ]; then
  ok "T2 idempotence : ensure-deps dry-run run1=$r1 run2=$r2 (no-op stable)"
else
  ko "T2 idempotence : exit run1=$r1 run2=$r2 (attendu 0/0)"
fi

# ---------------------------------------------------------------------------
# T2b — ensure-deps scopé (dry-run FORCÉ, sans réseau) — SCOPE-03
# ---------------------------------------------------------------------------
# VF_ENSURE_FORCE=1 (en plus de VF_ENSURE_DRY_RUN=1) court-circuite l'early-return de détection :
# les commandes scopées sont donc LOGUÉES même si GSD/Superpowers sont déjà installés sur la machine
# (cas dev/CI courant — sans FORCE, l'early-return skip masquerait les flags → faux-négatif).
# FORCE ne fait que loguer via run_cmd : AUCUN appel réseau ni install (dry-run uniquement).
ENS="$MOD/scripts/ensure-deps.sh"
t2b_fail=0

# (user|project|local) → flags GSD + Superpowers attendus.
# user → --global / --scope user ; project → --local / --scope project ; local → --local / --scope local.
assert_scope() {
  local scope="$1" gsd_flag="$2" sp_flag="$3" out
  out=$(VF_ENSURE_DRY_RUN=1 VF_ENSURE_FORCE=1 VF_SCOPE="$scope" bash "$ENS" 2>&1)
  if echo "$out" | "$GREP" -q -- "$gsd_flag" && echo "$out" | "$GREP" -q -- "$sp_flag"; then
    ok "T2b scope=$scope : GSD $gsd_flag + Superpowers $sp_flag logués (dry-run forcé)"
  else
    ko "T2b scope=$scope : flags attendus absents ($gsd_flag / $sp_flag)"
    t2b_fail=$((t2b_fail+1))
  fi
}

assert_scope user    "--global" "--scope user"
assert_scope project "--local"  "--scope project"
assert_scope local   "--local"  "--scope local"

# Rétro-compat : sans VF_SCOPE (dry-run forcé) → défaut LEGACY user (--global / --scope user).
out_default=$(VF_ENSURE_DRY_RUN=1 VF_ENSURE_FORCE=1 bash "$ENS" 2>&1)
if echo "$out_default" | "$GREP" -q -- "--global" && echo "$out_default" | "$GREP" -q -- "--scope user"; then
  ok "T2b rétro-compat : sans VF_SCOPE → --global + --scope user (défaut LEGACY)"
else
  ko "T2b rétro-compat : défaut LEGACY user attendu (--global / --scope user)"
  t2b_fail=$((t2b_fail+1))
fi

# Validation : scope invalide rejeté AVANT effet de bord (exit≠0). Pas besoin de FORCE (validation en tête).
VF_ENSURE_DRY_RUN=1 VF_SCOPE=bogus bash "$ENS" >/dev/null 2>&1
if [ $? -ne 0 ]; then
  ok "T2b validation : VF_SCOPE=bogus rejeté (exit≠0 avant effet de bord)"
else
  ko "T2b validation : VF_SCOPE=bogus aurait dû être rejeté (exit≠0)"
  t2b_fail=$((t2b_fail+1))
fi

# ---------------------------------------------------------------------------
# T3 — Routage AGENT.md : ≥11 VERBES DISTINCTS ET ≥11 lignes d'intentions NL
# ---------------------------------------------------------------------------
# D-09 (étape 12) : (a) comptait les cibles gsd-* canoniques citées dans l'agent. VERB-01 les
# bannit de la table de routage — l'agent route vers un verbe, le verbe connaît sa cible. Le
# compteur porte donc sur les VERBES /vf-* distincts de la table, à seuil inchangé (≥11).
AGENT="$AGENT_FILE"
# (a) verbes distincts cités dans les lignes de table (hors lignes commentaire).
distinct_targets=$("$GREP" -v '^#' "$AGENT" \
  | "$GREP" -E '^\|' \
  | "$GREP" -Eo '/vf-[a-z0-9-]+' \
  | sort -u | wc -l | tr -d ' ')
# (b) lignes d'intentions NL = lignes de la table de routage (| intention | action |)
#     hors header (« Intention ») et hors séparateur (|---|).
intent_lines=$("$GREP" -E '^\|' "$AGENT" \
  | "$GREP" -v -E '^\|[[:space:]]*-{2,}' \
  | "$GREP" -v -iE '^\|[[:space:]]*Intention' \
  | "$GREP" -c '|')

if [ "${distinct_targets:-0}" -ge 11 ] && [ "${intent_lines:-0}" -ge 11 ]; then
  ok "T3 routage : $distinct_targets verbes distincts ET $intent_lines lignes d'intentions NL (≥11/≥11)"
else
  ko "T3 routage : verbes distincts=$distinct_targets, lignes intentions=$intent_lines (attendu ≥11 chacun)"
fi

# ---------------------------------------------------------------------------
# T4 — Mapping /vf-* non orphelin (robuste à un index vide via fixture)
# ---------------------------------------------------------------------------
# Index de référence des cibles gsd-* : index disque s'il contient des skills,
# sinon fixture embarquée pour ne jamais produire de faux négatif.
INDEX_DISK="$REFS_DIR/gsd-skills-index.md"
index_has_skills=0
if [ -f "$INDEX_DISK" ] && "$GREP" -Eq 'gsd-[a-z0-9-]+' "$INDEX_DISK"; then
  index_has_skills=1
fi
# Fixture canonique : TOUTES les cibles portées par un verbe /vf-*, pipeline historique compris.
# Elle sert quand l'index disque est absent (CI, poste sans GSD) ET quand l'index versionné est en
# retard sur la chaîne réelle — sans elle, chaque verbe ajouté sort « orphelin » hors poste de dev.
# gsd-ingest-docs / gsd-import : place réservée pour /vf-ingest (étape 13), la fixture les connaît
# avant que le verbe n'existe.
# gsd-sketch / gsd-ui-phase / gsd-ui-review : cibles du module design. En lab installé, les skills
# des deux modules cohabitent à plat sous .claude/skills/ — la boucle ci-dessous les ramasse donc
# aussi. Les omettre rendrait la suite rouge chez l'utilisateur et verte ici : le piège n° 1.
FIXTURE_TARGETS="gsd-discuss-phase gsd-plan-phase gsd-mvp-phase gsd-execute-phase gsd-quick gsd-fast gsd-verify-work gsd-code-review gsd-debug gsd-autonomous gsd-ship gsd-pr-branch gsd-progress gsd-map-codebase gsd-new-project \
gsd-secure-phase gsd-add-tests gsd-audit-uat gsd-audit-fix gsd-validate-phase gsd-forensics \
gsd-inbox gsd-new-milestone gsd-complete-milestone gsd-milestone-summary gsd-audit-milestone \
gsd-phase gsd-undo gsd-review-backlog gsd-capture gsd-cleanup gsd-resume-work gsd-pause-work \
gsd-docs-update gsd-extract-learnings gsd-graphify gsd-explore gsd-spike gsd-spec-phase \
gsd-sketch gsd-ui-phase gsd-ui-review gsd-ingest-docs gsd-import"

# Vérifie qu'une cible gsd-X est connue (index disque ou fixture).
# Comparaison à frontière de mot : sans elle, « gsd-review » serait déclaré connu par la seule
# présence de « gsd-review-backlog » dans l'index (préfixes : gsd-review, gsd-phase, gsd-import…).
target_known() {
  local t="$1"
  if [ "$index_has_skills" -eq 1 ]; then
    "$GREP" -qE -- "${t}([^a-z0-9-]|$)" "$INDEX_DISK" && return 0
  fi
  case " $FIXTURE_TARGETS " in *" $t "*) return 0 ;; esac
  return 1
}

orphans=0
checked=0
for skill_md in "$MOD"/skills/vf-*/SKILL.md; do
  [ -f "$skill_md" ] || continue
  vfname="$(basename "$(dirname "$skill_md")")"
  # En lab, skills/ est partagé : on n'audite que les verbes de ce chantier (voir OWNED_VERBS).
  owned_verb "$vfname" || continue
  # Extrait toutes les cibles référencées dans le corps : gsd-X, brainstorming, ensure-deps.
  targets=$("$GREP" -Eo 'gsd-[a-z0-9-]+|brainstorming|ensure-deps' "$skill_md" | sort -u)
  if [ -z "$targets" ]; then
    # vf-dev = aiguilleur interne vers d'autres verbes /vf-* → cible interne acceptée.
    if "$GREP" -Eq 'vf-[a-z]+|vibeflow-dev' "$skill_md"; then
      checked=$((checked+1))
      continue
    fi
    ko "T4 mapping : $vfname ne référence aucune cible (orphelin)"
    orphans=$((orphans+1))
    continue
  fi
  for t in $targets; do
    case "$t" in
      brainstorming) : ;;            # superpowers — accepté
      ensure-deps)   : ;;            # bootstrap interne — accepté
      gsd-sdk)       : ;;            # CLI d'état GSD — pas un skill
      gsd-*)
        if ! target_known "$t"; then
          ko "T4 mapping : $vfname → cible orpheline « $t » (absente de l'index/fixture)"
          orphans=$((orphans+1))
        fi
        ;;
    esac
  done
  checked=$((checked+1))
done

if [ "$orphans" -eq 0 ]; then
  src=$([ "$index_has_skills" -eq 1 ] && echo "index disque" || echo "fixture canonique")
  ok "T4 mapping : $checked skill(s) /vf-* — aucun orphelin (source: $src)"
fi

# ---------------------------------------------------------------------------
# T5 — Densité par wc -l UNIQUEMENT (jamais le contrôleur de taille générique sur .md)
# ---------------------------------------------------------------------------
agent_lines=$(wc -l < "$AGENT" | tr -d ' ')
if [ "$agent_lines" -le 250 ]; then
  ok "T5 densité agent : AGENT.md = ${agent_lines}L (≤250)"
else
  ko "T5 densité agent : AGENT.md = ${agent_lines}L (>250)"
fi

skills_over=0
skills_total=0
for f in "$MOD"/skills/vf-*/SKILL.md; do
  [ -f "$f" ] || continue
  # En lab, skills/ est partagé entre modules : on n'audite que nos verbes (voir OWNED_VERBS).
  owned_verb "$(basename "$(dirname "$f")")" || continue
  skills_total=$((skills_total+1))
  n=$(wc -l < "$f" | tr -d ' ')
  if [ "$n" -gt 500 ]; then
    ko "T5 densité skill : $(basename "$(dirname "$f")")/SKILL.md = ${n}L (>500)"
    skills_over=$((skills_over+1))
  fi
done
if [ "$skills_over" -eq 0 ]; then
  ok "T5 densité skills : $skills_total skill(s) /vf-* tous ≤500L"
fi

# ---------------------------------------------------------------------------
# T6 — Install end-to-end via vibeflow-update.sh (best-effort, SKIP sinon)
# ---------------------------------------------------------------------------
INSTALLER="$REPO/_internal/vibeflow-update.sh"
if [ ! -f "$INSTALLER" ]; then
  skip "T6 install e2e : installeur introuvable ($INSTALLER)"
elif ! "$GREP" -q -- '-references' "$INSTALLER"; then
  skip "T6 install e2e : installeur ne câble pas encore la copie references agent (D7)"
else
  LAB="$(mktemp -d)"
  CACHE="$LAB/.vibeflow-cache"
  mkdir -p "$CACHE/dev-orchestrator"
  cp -r "$MOD/." "$CACHE/dev-orchestrator/" 2>/dev/null || true
  # Lance l'install dans le lab temporaire (VIBEFLOW_CACHE pointe sur le faux cache).
  if (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install dev-orchestrator >/dev/null 2>&1); then
    miss=0
    [ -f "$LAB/.claude/agents/dev-orchestrator.md" ] || { ko "T6 install : .claude/agents/dev-orchestrator.md manquant"; miss=1; }
    for ref in GSD-PIPELINE.md gsd-skills-index.md vocabulary-map.md intent-routing.md; do
      [ -f "$LAB/.claude/agents/dev-orchestrator-references/$ref" ] || { ko "T6 install : references/$ref manquant"; miss=1; }
    done
    # La rule de préséance (niveau 2) doit être posée sous .claude/rules/ : sans elle, la doctrine
    # existe en source mais n'est jamais chargée dans le lab — T13 ne le verrait pas, il lit la source.
    [ -f "$LAB/.claude/rules/vf-verb-precedence.md" ] || { ko "T6 install : .claude/rules/vf-verb-precedence.md manquant"; miss=1; }
    if [ "$miss" -eq 0 ]; then
      ok "T6 install e2e : agent + references (dont intent-routing) + rules/vf-verb-precedence.md présents"
    fi
  else
    skip "T6 install e2e : install non réalisable dans l'environnement (best-effort)"
  fi
  rm -rf "$LAB"
fi

# ---------------------------------------------------------------------------
# T7 — Garde-fou first-use présent dans AGENT.md (régression FIRST-01/FIRST-02)
# ---------------------------------------------------------------------------
# Présence du garde-fou sur fichier FILTRÉ des commentaires (hygiène grep-gate : un simple
# commentaire ne doit pas suffire). Pas de check densité ici (T5 le fait déjà via wc -l).
has_marker=$("$GREP" -v '^#' "$AGENT_FILE" | "$GREP" -ci 'first-use\|premier usage')
has_detect=0; "$GREP" -q -- '.planning' "$AGENT_FILE" && has_detect=1
has_vfinit=0; "$GREP" -q -- 'vf-init'   "$AGENT_FILE" && has_vfinit=1
has_noauto=$("$GREP" -v '^#' "$AGENT_FILE" | "$GREP" -ci 'new-project')

if [ "${has_marker:-0}" -ge 1 ] && [ "$has_detect" -eq 1 ] && [ "$has_vfinit" -eq 1 ] && [ "${has_noauto:-0}" -ge 1 ]; then
  ok "T7 first-use : garde-fou présent (détection .planning + délégation vf-init + new-project encadré)"
else
  ko "T7 first-use : garde-fou incomplet dans AGENT.md (marker=$has_marker detect=$has_detect vfinit=$has_vfinit noauto=$has_noauto)"
fi

# ---------------------------------------------------------------------------
# T8 — Équipe manager : 4 agents natifs conformes (spec 2026-07-09, ADR-044/029)
# ---------------------------------------------------------------------------
TEAM_AGENTS="vf-dev-manager vf-coder vf-reviewer vf-auditer"
WORKERS="vf-coder vf-reviewer vf-auditer"
t8_ok=1
for a in $TEAM_AGENTS; do
  f="$MOD/agents/$a.md"
  if [ ! -f "$f" ]; then ko "T8 agents : $a.md introuvable dans $MOD/agents/"; t8_ok=0; continue; fi
  for field in description model memory; do
    "$GREP" -q "^${field}:" "$f" || { ko "T8 agents : $a.md sans champ $field"; t8_ok=0; }
  done
  a_lines=$(wc -l < "$f" | tr -d ' ')
  [ "${a_lines:-999}" -le 250 ] || { ko "T8 agents : $a.md dépasse 250 lignes ($a_lines)"; t8_ok=0; }
done
[ "$t8_ok" -eq 1 ] && ok "T8 agents : 4 agents de l'équipe présents, frontmatter complet, ≤250L"

# T8b — vf-internal : présent sur les 3 workers, absent du manager (Pattern 12)
t8b_ok=1
for w in $WORKERS; do
  "$GREP" -q "^vf-internal: true" "$MOD/agents/$w.md" 2>/dev/null || { ko "T8b vf-internal manquant : $w"; t8b_ok=0; }
done
if "$GREP" -q "^vf-internal:" "$MOD/agents/vf-dev-manager.md" 2>/dev/null; then
  ko "T8b : vf-dev-manager déclaré vf-internal (doit rester exposé)"; t8b_ok=0
fi
[ "$t8b_ok" -eq 1 ] && ok "T8b vf-internal : workers internes marqués, manager exposé"

# ---------------------------------------------------------------------------
# T9 — Contrats de mission : source unique + renvois (DRY)
# ---------------------------------------------------------------------------
CONTRACTS="$REFS_DIR/mission-contracts.md"
if [ -f "$CONTRACTS" ]; then
  if "$GREP" -qi "Brief de mission" "$CONTRACTS" && "$GREP" -qi "Rapport de mission" "$CONTRACTS" \
     && "$GREP" -q "SEUIL_EQUIPE" "$CONTRACTS"; then
    ok "T9 contrats : mission-contracts.md présent (Brief + Rapport + SEUIL_EQUIPE)"
  else
    ko "T9 contrats : mission-contracts.md incomplet (Brief/Rapport/SEUIL_EQUIPE manquant)"
  fi
  renvois=0
  "$GREP" -q "mission-contracts" "$AGENT_FILE" && renvois=$((renvois+1))
  "$GREP" -q "mission-contracts" "$MOD/skills/vf-auto/SKILL.md" && renvois=$((renvois+1))
  "$GREP" -q "mission-contracts" "$MOD/agents/vf-dev-manager.md" && renvois=$((renvois+1))
  if [ "$renvois" -eq 3 ]; then
    ok "T9 renvois : router + vf-auto + manager renvoient aux contrats (3/3)"
  else
    ko "T9 renvois : $renvois/3 renvois vers mission-contracts.md"
  fi
else
  ko "T9 contrats : $CONTRACTS introuvable"
fi

# ---------------------------------------------------------------------------
# T10 — Détection mission (router) + aiguillage taille (vf-auto)
# ---------------------------------------------------------------------------
if "$GREP" -q "vf-dev-manager" "$AGENT_FILE"; then
  ok "T10 router : AGENT.md route les missions vers vf-dev-manager"
else
  ko "T10 router : aucune mention de vf-dev-manager dans AGENT.md"
fi
if "$GREP" -q "SEUIL_EQUIPE" "$MOD/skills/vf-auto/SKILL.md" \
   && "$GREP" -q "vf-dev-manager" "$MOD/skills/vf-auto/SKILL.md"; then
  ok "T10 vf-auto : aiguillage taille présent (SEUIL_EQUIPE → vf-dev-manager)"
else
  ko "T10 vf-auto : aiguillage taille absent de vf-auto/SKILL.md"
fi

# ---------------------------------------------------------------------------
# T11 — Généricité : aucun renvoi vers un chemin absent d'un lab installé (DM5)
# ---------------------------------------------------------------------------
# Le module est distribué : ce qu'il livre ne doit référencer QUE des chemins qui existent
# chez l'utilisateur. Un renvoi vers `.planning/research/` ou `docs/_mission/` (dossiers du
# dépôt de développement, jamais installés) est un lien mort en lab — c'est le défaut réel,
# indépendamment du nom du projet qui l'a introduit.
#
# Périmètre BORNÉ au module : en lab, agents/ est partagé entre tous les modules installés.
# On n'audite que ce que ce module possède — son agent, ses references, ses 4 agents d'équipe.
t11_targets="$AGENT_FILE"
[ -d "$REFS_DIR" ] && t11_targets="$t11_targets $REFS_DIR"
for a in vf-dev-manager vf-coder vf-reviewer vf-auditer; do
  [ -f "$MOD/agents/$a.md" ] && t11_targets="$t11_targets $MOD/agents/$a.md"
done
# shellcheck disable=SC2086
if "$GREP" -rqE '\.planning/research/|docs/_mission' $t11_targets 2>/dev/null; then
  # shellcheck disable=SC2086
  hit=$("$GREP" -rlE '\.planning/research/|docs/_mission' $t11_targets 2>/dev/null | head -3 | tr '\n' ' ')
  ko "T11 généricité : renvoi vers un chemin non installé en lab — $hit"
else
  ok "T11 généricité : aucun renvoi vers un chemin absent d'un lab (périmètre borné au module)"
fi

# ---------------------------------------------------------------------------
# T12 — Anti-collision : démarcations croisées des descriptions (= T11 de la spec)
# ---------------------------------------------------------------------------
# La description d'un verbe EST le code du routeur de niveau 1 : c'est elle qui départage deux
# gestes voisins au matching. Le contrôle porte sur les groupes à recouvrement lexical avéré
# (D-07) : réciprocité STRICTE à l'intérieur d'un groupe, unilatérale admise ailleurs. Un
# contrôle universel produirait des faux positifs sur les renvois génériques de vf-dev.
# Les deux modules sont lus (dev + design) : la démarcation sketch/design/spike les traverse.

# Localise le SKILL.md d'un verbe : module courant, puis module design (source ou lab à plat).
skill_file() {
  local v="$1"
  [ -f "$MOD/skills/$v/SKILL.md" ] && { echo "$MOD/skills/$v/SKILL.md"; return 0; }
  [ -f "$REPO/design-orchestrator/skills/$v/SKILL.md" ] && { echo "$REPO/design-orchestrator/skills/$v/SKILL.md"; return 0; }
  return 1
}

# Description du frontmatter, aplatie sur une ligne (bloc scalaire « description: > » compris).
verb_desc() {
  awk '/^description:/{f=1;print;next} f&&/^[A-Za-z_-]+:/{exit} f&&/^---[[:space:]]*$/{exit} f{print}' "$1" | tr '\n' ' '
}

# Groupes de collision (D-07). Réciprocité stricte à l'intérieur de chaque groupe.
COLLISION_GROUPS="
vf-test:vf-testgen
vf-review:vf-gaps
vf-brainstorm:vf-explore:vf-spike:vf-spec
vf-map:vf-learn
vf-progress:vf-resume
vf-debug:vf-forensics
vf-plan:vf-phase
vf-ship:vf-inbox
vf-sketch:vf-design:vf-spike
vf-test:vf-spike
vf-progress:vf-gaps
"

# Verbes du module design : leur absence n'est pas un échec (module non installé).
DESIGN_VERBS="vf-design vf-sketch"
is_design_verb() { case " $DESIGN_VERBS " in *" $1 "*) return 0 ;; esac; return 1; }

# « $1 (description) repousse-t-elle vers le verbe $2 ? », à frontière de mot :
# /vf-test est un préfixe de /vf-testgen, /vf-plan de /vf-planning — sans la frontière, une
# démarcation supprimée resterait verte parce que sa voisine porte le même début de nom.
cites_verb() { echo "$1" | "$GREP" -qE "/${2}([^a-z0-9-]|$)"; }

t12_fail=0
t12_groups=0
for group in $COLLISION_GROUPS; do
  members="$(echo "$group" | tr ':' ' ')"
  # Un verbe absent du disque : SKIP si SEULS des verbes design manquent (module non installé),
  # KO dès qu'un verbe du module courant manque — sinon un groupe mixte masquerait la régression.
  missing=""; missing_dev=""
  for m in $members; do
    skill_file "$m" >/dev/null && continue
    missing="$missing $m"
    is_design_verb "$m" || missing_dev="$missing_dev $m"
  done
  if [ -n "$missing" ]; then
    if [ -n "$missing_dev" ]; then
      ko "T12 groupe [$members] : verbe(s) du module introuvable(s) —$missing_dev"; t12_fail=$((t12_fail+1))
    else
      skip "T12 groupe [$members] : module design absent —$missing"
    fi
    continue
  fi
  t12_groups=$((t12_groups+1))
  # Un verbe muet (aucun voisin cité) est signalé une fois ; on n'ajoute pas de KO de réciprocité
  # à son encontre, ce serait le même défaut compté deux fois.
  silent=""
  for a in $members; do
    desc_a="$(verb_desc "$(skill_file "$a")")"
    cites=0
    for b in $members; do
      [ "$a" = "$b" ] && continue
      cites_verb "$desc_a" "$b" && cites=$((cites+1))
    done
    if [ "$cites" -eq 0 ]; then
      ko "T12 démarcation : /$a ne cite aucun voisin du groupe [$members]"
      t12_fail=$((t12_fail+1)); silent="$silent $a"
    fi
  done
  for a in $members; do
    desc_a="$(verb_desc "$(skill_file "$a")")"
    for b in $members; do
      [ "$a" = "$b" ] && continue
      case " $silent " in *" $b "*) continue ;; esac   # déjà signalé comme muet
      cites_verb "$desc_a" "$b" || continue
      # Réciprocité : b doit repousser vers a.
      if ! cites_verb "$(verb_desc "$(skill_file "$b")")" "$a"; then
        ko "T12 réciprocité : /$a repousse vers /$b, mais /$b ne repousse pas vers /$a"
        t12_fail=$((t12_fail+1))
      fi
    done
  done
done

# Groupe 6 — unilatéral par construction : /vf-audit appartient au module validator et n'est pas
# modifiable ici (D-01). vf-gaps doit le nommer ; la réciprocité est assurée par la chasse gardée.
if f_gaps="$(skill_file vf-gaps)"; then
  cites_verb "$(verb_desc "$f_gaps")" "vf-audit" || {
    ko "T12 collision 6 : vf-gaps ne renvoie pas l'audit de conformité du lab vers /vf-audit"
    t12_fail=$((t12_fail+1)); }
else
  ko "T12 collision 6 : vf-gaps introuvable"; t12_fail=$((t12_fail+1))
fi

# Chasse gardée + interdit n°6 du gabarit, sur TOUTES les descriptions des deux modules :
#  (a) aucune ne CAPTE l'audit de conformité du lab (réservé à /vf-audit) — on n'inspecte que la
#      zone de capture, avant le premier « ✘ » : les contre-exemples, eux, ont le droit et le
#      devoir de nommer /vf-audit ;
#  (b) chacune repousse au moins une intention voisine (« ✘ … → /vf-… »). Une description qui
#      capte tout ne départage rien — c'est le mode d'échec principal du chantier, et il touche
#      aussi les 20 verbes hors groupes de collision. Ce contrôle-là est universel : il ne dit
#      rien de la réciprocité, il n'entre donc pas en conflit avec D-07.
GUARD_RE='conformité (du lab|méthodologique)|audite (le|ce) lab|audite les agents|densité des agents'
t12_desc=0
for sm in "$MOD"/skills/vf-*/SKILL.md "$REPO"/design-orchestrator/skills/vf-*/SKILL.md; do
  [ -f "$sm" ] || continue
  vname="$(basename "$(dirname "$sm")")"
  # Verbes des autres modules (conductor, validator, planning-core…) : hors périmètre, ils ne
  # suivent pas ce gabarit et ne sont pas modifiables d'ici (D-01).
  owned_verb "$vname" || continue
  d="$(verb_desc "$sm")"
  t12_desc=$((t12_desc+1))
  if echo "${d%%✘*}" | "$GREP" -qiE "$GUARD_RE"; then
    ko "T12 chasse gardée : $vname capte l'audit de conformité du lab (réservé à /vf-audit)"
    t12_fail=$((t12_fail+1))
  fi
  # Le contre-exemple doit NOMMER un verbe : « ✘ … → /vf-… » dans le même segment (jusqu'au ✘
  # suivant). Un ✘ de forme libre suivi n'importe où d'un /vf-… ne départage rien.
  if ! echo "$d" | "$GREP" -qE '✘[^✘]*→[[:space:]]*/vf-[a-z0-9-]+'; then
    ko "T12 démarcation : $vname ne repousse aucune intention voisine (✘ … → /vf-…)"
    t12_fail=$((t12_fail+1))
  fi
done

if [ "$t12_fail" -eq 0 ]; then
  ok "T12 anti-collision : $t12_groups groupe(s) à réciprocité stricte, $t12_desc description(s) avec contre-exemple + chasse gardée"
fi

# ---------------------------------------------------------------------------
# T13 — Préséance des verbes : rule globale conforme et référencée (= T12 de la spec)
# ---------------------------------------------------------------------------
# Source : $MOD/rules/ en source comme en lab (l'installeur pose rules/*.md sous .claude/rules/).
RULE="$MOD/rules/vf-verb-precedence.md"
t13_fail=0
if [ ! -f "$RULE" ]; then
  ko "T13 préséance : $RULE introuvable"; t13_fail=$((t13_fail+1))
else
  # Rule GLOBALE (Tier 1) : pas de frontmatter paths: — une intention n'a pas de chemin de fichier.
  if "$GREP" -qE '^[[:space:]]*paths:' "$RULE"; then
    ko "T13 préséance : la rule déclare paths: — elle ne serait chargée qu'à la lecture d'un fichier correspondant"
    t13_fail=$((t13_fail+1))
  fi
  rule_lines=$(wc -l < "$RULE" | tr -d ' ')
  if [ "${rule_lines:-999}" -gt 40 ]; then
    ko "T13 préséance : rule = ${rule_lines}L (>40, elle est chargée en permanence)"; t13_fail=$((t13_fail+1))
  fi
  "$GREP" -q 'vf-verb-precedence' "$AGENT_FILE" || {
    ko "T13 préséance : AGENT.md ne référence pas la rule"; t13_fail=$((t13_fail+1)); }
fi
# Assertion complémentaire de T3 (VERB-01) : la table de routage ne cite AUCUNE cible interne.
table_gsd=$("$GREP" -E '^\|' "$AGENT_FILE" | "$GREP" -cE 'gsd-[a-z0-9-]+')
if [ "${table_gsd:-0}" -ne 0 ]; then
  ko "T13 table propre : $table_gsd ligne(s) de la table de routage citent une cible gsd-* (VERB-01)"
  t13_fail=$((t13_fail+1))
fi
[ "$t13_fail" -eq 0 ] && ok "T13 préséance : rule globale (${rule_lines}L, sans paths:) référencée par l'agent, table sans cible interne"

# ---------------------------------------------------------------------------
# T14 — Exhaustivité du routage (= T13 de la spec)
# ---------------------------------------------------------------------------
# (a) Chaque skill gsd-* de l'index factuel est routé par intent-routing.md.
# (b) Durcissement D-03 : toute cible portée par un VERBE dans intent-routing.md est réellement
#     citée dans le corps de ce verbe. Sans ça, la table pourrait promettre un routage que le
#     verbe ne fait pas. Les lignes « — (agent) » sont exclues : pas de verbe, délégation directe.
# ($ROUTING est défini en tête du script : c'est aussi la source de la liste de propriété.)
t14_fail=0
if [ ! -f "$ROUTING" ]; then
  ko "T14 exhaustivité : $ROUTING introuvable"; t14_fail=$((t14_fail+1))
else
  # (a) — comparaison sur les lignes « | gsd-… | » de l'index (évite les faux positifs gsd-index/gsd-sdk).
  if [ -f "$INDEX_DISK" ]; then
    indexed=$("$GREP" -Eo '^\|[[:space:]]*`?gsd-[a-z0-9-]+' "$INDEX_DISK" | "$GREP" -Eo 'gsd-[a-z0-9-]+' | sort -u)
  else
    indexed=""
  fi
  if [ -z "$indexed" ]; then
    skip "T14 exhaustivité (a) : index factuel vide — GSD non installé (pas un échec)"
  else
    missing_routed=""
    n_indexed=0
    for s in $indexed; do
      n_indexed=$((n_indexed+1))
      # Frontière de mot : « gsd-review » ne doit pas être déclaré routé par « gsd-review-backlog ».
      "$GREP" -qE -- "${s}([^a-z0-9-]|$)" "$ROUTING" || missing_routed="$missing_routed $s"
    done
    if [ -n "$missing_routed" ]; then
      ko "T14 exhaustivité (a) : skill(s) de l'index non routé(s) par intent-routing.md —$missing_routed"
      t14_fail=$((t14_fail+1))
    else
      ok "T14 exhaustivité (a) : $n_indexed skill(s) de l'index tous routés par intent-routing.md"
    fi
  fi

  # (b) — cible promise = cible citée par le verbe qui la porte.
  broken=""
  pairs=0
  while IFS='|' read -r _ _intent verbe cible _rest; do
    v=$(echo "$verbe" | "$GREP" -oE '/vf-[a-z0-9-]+' | head -1)
    [ -n "$v" ] || continue                     # ligne « — (agent) » ou hors table de routage
    tgts=$(echo "$cible" | "$GREP" -Eo 'gsd-[a-z0-9-]+' | sort -u)
    [ -n "$tgts" ] || continue
    vname="${v#/}"
    vfile="$(skill_file "$vname")" || {
      # Verbe absent du poste : place réservée (ex. /vf-ingest, étape 13) ou module non installé.
      skip "T14 (b) : $vname introuvable — cibles non vérifiées : $(echo $tgts)"
      continue; }
    for t in $tgts; do
      pairs=$((pairs+1))
      "$GREP" -qE -- "${t}([^a-z0-9-]|$)" "$vfile" || broken="$broken ${vname}→${t}"
    done
  done < <("$GREP" -E '^\|' "$ROUTING" | "$GREP" -v -E '^\|[[:space:]]*-{2,}' | "$GREP" -v -iE '^\|[[:space:]]*Intention')
  if [ -n "$broken" ]; then
    ko "T14 exhaustivité (b) : cible(s) promise(s) par la doctrine mais absente(s) du corps du verbe —$broken"
    t14_fail=$((t14_fail+1))
  elif [ "$pairs" -eq 0 ]; then
    # Plancher anti-test-vacant : zéro couple vérifié = le parsing de la table a cessé de mordre
    # (colonnes déplacées, format changé), pas « tout va bien ».
    ko "T14 exhaustivité (b) : aucun couple verbe→cible extrait de intent-routing.md (format de table changé ?)"
    t14_fail=$((t14_fail+1))
  else
    ok "T14 exhaustivité (b) : $pairs couple(s) verbe→cible vérifié(s), chacun cité par son verbe"
  fi

  # (c) — contre-poids de la borne de propriété : un verbe livré mais absent de la doctrine sort du
  # périmètre d'audit (OWNED_VERBS) SANS BRUIT. Oublier une ligne de table désarmerait alors les
  # contrôles de ce verbe. Vérifiable en SOURCE uniquement — en lab, skills/ est plat et partagé,
  # l'égalité verbes-sur-disque / verbes-déclarés n'y a aucun sens.
  if [ -n "$OWNED_VERBS" ] && [ -f "$MOD/AGENT.md" ]; then
    undeclared=""
    for d in "$MOD"/skills/vf-*/; do
      [ -d "$d" ] || continue
      v="$(basename "$d")"
      owned_verb "$v" || undeclared="$undeclared $v"
    done
    if [ -n "$undeclared" ]; then
      ko "T14 (c) : verbe(s) du module absent(s) de intent-routing.md — donc NON audités —$undeclared"
      t14_fail=$((t14_fail+1))
    else
      ok "T14 (c) : tous les verbes du module sont déclarés dans la doctrine (périmètre d'audit complet)"
    fi
  fi
fi

# ---------------------------------------------------------------------------
echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ]
