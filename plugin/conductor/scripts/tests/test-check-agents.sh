#!/usr/bin/env bash
# test-check-agents.sh — Suite du gate de conformité NATIVE des agents (ADR-044).
#
# check-agents.sh :
#   T1 — agent complet (name/description/model/memory/skills existants) → exit 0
#   T2 — agent sans frontmatter → exit 1
#   T3 — agent sans description / sans model / sans memory → exit 1 (3 erreurs)
#   T4 — enums invalides (model, memory, effort) → exit 1
#   T5 — champ inconnu (typo) → warning, non bloquant si socle OK
#   T6 — skill déclaré introuvable : warning en défaut, ERREUR en --strict
#   T7 — budget préchargement : skill > 200L → warning ; cumul > VF_PRELOAD_MAX → erreur
#   T8 — skill disable-model-invocation:true préchargé → erreur
#   T9 — --hook : exit 0 même non conforme, signalement compact
#   T10 — contracts.md/README.md ignorés (pas des agents)
#
# guard-agent-write.sh (PreToolUse Write) :
#   T11 — Write d'un agent non natif dans .claude/agents/ → DENY avec squelette
#   T12 — Write d'un agent conforme → allow
#   T13 — Write hors .claude/agents/ ou contracts.md → allow
#   T14 — stdin invalide → allow silencieux (fail-open)
#
# Lint des allowlists Agent(...)/Task(...) (Phase 16, ADR-044) :
#   T25 — allowlist reelle mixte (natif+tiers+cross-module) --strict → exit 0 (anti-faux-positif)
#   T26 — parenthese non fermee → exit 1 (classe syntaxe, non affectee par --strict)
#   T27 — Agent() vide → exit 1
#   T28 — outil hors set connu (Reed) : warning en defaut, ERREUR en --strict ; Read reste vert
#   T29 — Agent(vf-codeur) (typo) reste VERT meme en --strict (non-regression faux positif)
#   T30 — meme mutant sous --resolve-agents=strict + registre → exit 1 (preuve discriminance)
#   T31 — flow list [Read, Agent(x, y), Bash(git:*)] : 0 finding fantome
#   T32 — prefixe tiers (gsd-planner sans model/memory) → ignore ; --no-third-party-prefix → exit 1
#   T33 — Task(...) alias legacy → reste vert
#   T34 — Agent nu (sans allowlist) → warning "dispatch non cloisonne", non bloquant
#
# Correctifs post-revue (2 juges independants, re-entree mission Phase 16) :
#   T35 — champ tools: ENTIEREMENT quote ('tools: "Read, Agent(x)"') → conforme (defaut 1)
#   T36 — ligne vide dans une liste bloc tools: ne perd plus les puces suivantes (defaut 2)
#   T37 — parenthese EN TROP 'Agent(a))' → exit 1 (pinne split_depth seul, defaut 3)
#   T38 — entree vide au niveau token (virgule orpheline 'Read,,Agent(x)') → exit 1
#   T39 — entree vide DANS une allowlist 'Agent(a,,b)' → exit 1
#   T40 — espace avant la parenthese 'Agent (x)' → exit 1
#   T41 — token hors charset au niveau bare (sans parenthese) → exit 1
#   T42 — name invalide (majuscules/espaces) → exit 1
#   T43 — permissionMode invalide → exit 1
#   T44 — isolation invalide → exit 1
#   T45 — background invalide → exit 1
#   T46 — maxTurns invalide → exit 1
#   T47 — skills absent → warning non bloquant
#   T48 — description < 30c → warning non bloquant
#   T49 — tools absent → warning non bloquant (herite tout)
#   T50 — name different du nom de fichier → warning non bloquant
#
# Gate final (3 ecarts en-tete <-> comportement, re-entree Phase 16 exec-lint) :
#   T51 — --resolve-agents=<valeur invalide> → exit 1 explicite (plus un skip muet)
#   T52 — --third-party-prefix ACCUMULE au-dessus du defaut gsd- (ne l'ecrase plus)
#   T53 — compteurs distincts : fichiers agent tiers non lintes != entrees d'allowlist resolues
#   T54 — nit : 'Agent(a))' (parenthese en trop) → libelle distinct de 'non fermee'
#
# Assertion sur l'ARBRE REEL (WINDOWS #1, Phase 20 reliquat) — T72 seul cas de la suite qui ne
# pointe PAS vers une fixture $AG jetable : balaie les agents reellement poses sous
# plugin/*/agents (perimetre exact des 6 dossiers audites par la CI), pas une liste codee en dur.
#   T72 — chaque agent memory: + tools: sans Write/Edit porte disallowedTools: Write, Edit ;
#         echoue si la decouverte est vide (anti "vert a vide", precedent Phase 19)
#
# effort: EXIGE (zone 6, Phase 24 — GSDA-20/21) : le champ etait valide S'IL ETAIT PRESENT,
# donc omissible en silence. Le durcissement transpose le patron du bloc model:.
#   T73 — agent LOCAL complet mais sans effort: → ERREUR bloquante nommant effort + ses valeurs
#   T74 — meme manque sur un agent TIERS (prefixe gsd- par defaut) → 0 erreur, 0 warning (T-24-01-01)
#   T75 — DISCRIMINANCE PAR MUTATION sur l'arbre reel : ligne effort: retiree → rouge, restauree
#         → vert ; mutation confirmee effective par `cmp` (jamais par `diff`, menteur ici)
#
# Marge de profondeur de dispatch (zone 6, Phase 24 — GSDA-22 ; hotfix v2.63.2, 2026-09-17) :
#   T76 — la lecture du 2026-08-04 (descripteur maxDepth: 5 → "deux niveaux de marge") est
#         marquee PERIMEE par la mesure du 2026-09-17 : outils Agent/Task ABSENTS a la
#         profondeur 3, profondeurs visees manager 1 / vf-coder 2 / briques GSD 3, descripteur
#         verbatim (7 champs) toujours recopie
#
# Manifeste daté (Phase 42, FABR-01, D-01/D-03/D-17) — la suite juge la LOGIQUE du gate contre un
# manifeste DATE DU JOUR (harnais mk_gate_dir/mk_manifest, verifie_le recalcule a chaque run) :
# source unique (D-01, aucune copie de repli dans le script), refus explicite sur manifeste absent
# ou invalide (D-03), contenu D-17 (trois outils ajoutes, aucun retire), silence de code sous
# --hook et fail-open documente de la garde d'ecriture. La fraicheur du manifeste VERSIONNE (celui
# du depot) est jugee par la CI (42-04), jamais ici.
#   T77 — manifeste absent + agent conforme, --strict → rc=1, MANIFESTE-ILLISIBLE ; dossier
#         d'agents vide, --strict → rc=3 (F13 inchange, manifeste non requis)
#   T78 — manifeste tronque (JSON invalide) + agent conforme, --strict → rc=1, MANIFESTE-ILLISIBLE
#   T79 — schema invalide (9 sous-cas : valide_jours absent/0/booleen, liste absente, valeurs
#         vides, verifie_le non ISO, source non https, liste inconnue, valeur hors charset) →
#         rc=1, MANIFESTE-ILLISIBLE dans chaque cas
#   T80 — source unique (D-01) : manifeste prive d'un outil/champ → refus/avertissement le citant ;
#         manifeste complet → absent
#   T81 — manifeste VERSIONNE copie tel quel (dates d'origine) → agent conforme sans
#         MANIFESTE-ILLISIBLE ; ListAgents/SendFeedback/SubagentHandback et experimental acceptes
#   T82 — --hook : manifeste absent → rc=0 ET sortie contenant MANIFESTE-ILLISIBLE (silence de
#         code, jamais de message) ; garde d'ecriture sur agent conforme → sortie vide (fail-open)
#
# Invocation nue sur cible absente (Phase 42, D-20, CONCERNS.md:349) :
#   T103 — cible ABSENTE (aucun .claude/agents sur le chemin), invocation SANS AUCUN FLAG (ni
#          --strict, ni --hook, ni --agents-dir, ni --file) → rc=3, sortie contenant INDETERMINE
#          et CIBLE-ABSENTE (jeton distinct du jeton F13 existant) ; jumeau vert : meme invocation
#          mais .claude/agents PRESENT et VIDE → rc=0, "rien a verifier", jamais CIBLE-ABSENTE
#          (regime T23 inchange) ; T55 et T56 rejoues verts sans modification (non-regression
#          explicite du harnais D-24 existant)
#
# Fraîcheur du manifeste (Phase 42, FABR-02, D-02/D-04/D-05) — la suite juge la LOGIQUE de
# rétrogradation contre un manifeste daté DU JOUR (mk_gate_dir/mk_manifest, même harnais que
# T77-T82) : l'INDÉTERMINÉ (exit 3) n'est rendu que sous --manifest-freshness=strict (D-04), un
# manifeste périmé rétrograde en avertissement « outil hors du set connu » et « nom d'agent non
# résolu » (suffixe retrograde) dans tous les autres contextes (D-05), jamais « champ inconnu »,
# jamais model/memory/effort (Pitfall 3). Deux mutants QUAL-01 (MUT-F1, MUT-F2) et un troisième
# posé ici pour la ligne cible_absente de 42-01 (MUT-D20, faute de harnais de mutation plus tôt) :
#   T83 — manifeste périmé + agent `tools: Read, Reed` + --strict → rc=0, warning suffixé
#         retrograde ; jumeau frais → rc=1 sans retrograde
#   T84 — périmé + --manifest-freshness=strict + agent conforme → rc=3 INDETERMINE
#         MANIFESTE-PERIME, jamais « ✓ agents conformes » ; frais + même option → rc=0 ; périmé
#         sans option → rc=0, MANIFESTE-PERIME présent, jamais ✗
#   T85 — bornes : âge = valide_jours → rc=0 sans MANIFESTE-PERIME ; âge = valide_jours + 1 →
#         rc=3 ; valide-jours=5 : âge 5 → rc=0, âge 6 → rc=3
#   T86 — date-future=outils (autres listes du jour) + option strict → rc=3, DATE-FUTURE ; sans
#         option → rc=0, MANIFESTE-PERIME
#   T87 — --hook : périmé + agent conforme (skills déclaré) → rc=0, sortie avec MANIFESTE-PERIME ;
#         frais + même agent → sortie vide ; dossier vide + --strict + périmé → rc=3 sans
#         MANIFESTE-PERIME (fraîcheur non évaluée, F13 inchangé)
#   T88 — Pitfall 3 : périmé + model/memory/effort invalides → rc=1, les trois restent bloquants
#   T89 — périmé + --resolve-agents=strict + allowlist non résolue (registre T30) → rc=0, « non
#         resolu » et retrograde ; jumeau frais → rc=1
#   T90 — garde d'écriture : dossier périmé + `tools: Read, Reed` → sortie vide (laisse passer) ;
#         dossier frais → refus JSON citant « outil hors du set connu » ; valeur d'option
#         inconnue → rc=1, « --manifest-freshness invalide »
#   MUT-F1 — `perimees = manifeste_perime(` → `perimees = []` (fixture T84) : rc_original=3,
#         rc_mutant=0
#   MUT-F2 — `retrograder = bool(perimees)` → `retrograder = False` (fixture T83) : rc_original=0,
#         rc_mutant=1
#   MUT-D20 (CORRECTIF DE REVUE, mission revise-42c) — `cible_absente = (not single) and not
#         os.path.isdir(agents_dir)` → `cible_absente = False` sur le gate déjà modifié par 42-01
#         (fixture T103, rejouée nue) : rc_original=3, rc_mutant=0 — posé ici car les helpers de
#         mutation (make_gate_mutant/okmut/komut) n'existent qu'à partir de cette tâche
#
# Invariants de doctrine (Phase 42, FABR-03, D-06 à D-11) — TOUJOURS des erreurs, jamais des
# avertissements, quel que soit --strict (D-11) ; chacun a son jumeau négatif et sa mutation
# QUAL-01 prouvée rouge, I1 et I7 en plus sur un porteur RÉEL du dépôt (mutation opposée par cmp,
# patron T75, via le helper `juger_mutation_reelle`) :
#   T91 — I1 (D-06) : vf-internal: true sans le marqueur « Worker interne » dans description: →
#         rc=1 invariant I1 ; marqueur sans vf-internal: true → rc=1 invariant I1 ; les deux ou
#         aucun des deux → rc=0 ; mutation réelle sur `plugin/mobile-test-team/agents/
#         vf-test-runner.md` (copie dont le marqueur perd « interne » après « Worker ») → rouge,
#         copie restaurée → verte
#   T91b — I1 (D-18) : forme à DEUX dispatcheurs nommés de `vf-test-orchestrator` (« Worker
#         interne — dispatché par vf-dev-manager ou par le mode autonome (vf-auto)… ») avec
#         vf-internal: true → rc=0, aucun invariant I1 (le nombre de dispatcheurs nommés n'entre
#         jamais en ligne de compte) ; jumeau négatif : même description sans vf-internal: true →
#         rc=1 invariant I1
#   T92 — I4 : disallowedTools: Bash(rm:*) (spécifieur) → rc=1 invariant I4 ; disallowedTools:
#         Bash (sans spécifieur) → rc=0
#   T95 — I7 : vf-mcp-consumer: true sans vf-requires → rc=1 invariant I7 ; vf-requires:
#         autre-chose (sans mcp-servers) → rc=1 invariant I7 ; vf-mcp-tools + vf-requires:
#         mcp-servers → rc=0 ; mutation réelle sur vf-test-runner.md (copie sans sa ligne
#         vf-requires) → rouge, copie restaurée → verte
#   MUT-I1, MUT-I4, MUT-I7 — `errors.extend(invariant_i1(` (resp. i4, i7) → `pass` sur la fixture
#         rouge de l'invariant correspondant : rc_original=1, rc_mutant=0
#   Fixtures préexistantes remises en conformité par l'armement de I7 : T67/T68 (vf-mcp-tools /
#         vf-mcp-tool sans vf-requires) reçoivent `vf-requires: mcp-servers`, rc/assertions
#         inchangés — aucune fixture préexistante n'est affaiblie par I1 ou I4 (zéro fixture
#         portant vf-internal/« Worker interne » ou un disallowedTools à spécifieur avant T91/T92)
#
# Invariants I5/I6 — analyse pure des allowlists (Phase 42, FABR-03, D-07/D-08, 42-05 Tâche 3) :
# I6 est TOUJOURS armé (indépendant de l'arbitrage D-19). I5 est armé SEULEMENT sur
# ARBITRAGE-MAINTENIR (sonde de la Tâche 2 rejouée avant cette tâche) :
#   T94 — I6 (D-07, toujours) : tools: Agent(...) non vide, non vf-internal, sans SendMessage →
#         rc=1 invariant I6 ; même allowlist avec SendMessage → rc=0 ; même allowlist avec
#         vf-internal: true + marqueur « Worker interne » → rc=0, aucun invariant I6 ; `Agent` nu
#         (sans parenthèses) → rc=0, aucun invariant I6 ; mutation réelle sur
#         `plugin/business-pilot-bundle/agents/vf-business-manager.md` (copie sans son jeton
#         SendMessage) → rouge, copie restaurée → verte
#   T93 — I5 (D-08, seulement si ARBITRAGE-MAINTENIR) : disallowedTools: Write, Edit + aucune
#         allowlist Agent(...)/Task(...) non vide, sans omitClaudeMd: true → rc=1 invariant I5 ;
#         même agent avec omitClaudeMd: true → rc=0 ; forme vf-reviewer (allowlist Agent(...) non
#         vide + disallowedTools Write, Edit, sans omitClaudeMd) → rc=0, aucun invariant I5 ;
#         mutation réelle sur `plugin/content-bundle/agents/content-clarity-judge.md` (copie sans
#         sa ligne omitClaudeMd, posée par cette même tâche) → rouge, copie restaurée → verte
#   T96 — corpus réel + check-blueprints.sh, adapté à la branche de l'arbitrage : les six
#         plugin/*/agents et plugin/*/AGENT.md passent --strict sans « invariant I6 » (ni
#         « invariant I5 » si armé) ; anti-vert-à-vide (au moins 6 dossiers découverts)
#   MUT-I6 (toujours), MUT-I5 (seulement si ARBITRAGE-MAINTENIR) — `errors.extend(invariant_i6(`
#         (resp. `invariant_i5(`) → `pass` sur la fixture rouge correspondante : rc_original=1,
#         rc_mutant=0
#   Fixtures préexistantes remises en conformité par l'armement de I6 (TOUJOURS, manager-shaped,
#         un `SendMessage` ajouté avant leur `Agent(`/`Task(` : T25, T28, T28b, T29, T30b, T31,
#         T33, T35, T36, T53) et de I5 (SEULEMENT si ARBITRAGE-MAINTENIR, juge-shaped, un
#         `omitClaudeMd: true` ajouté : T59, T62-T66, T67, T70, T77/T78/T79/T82/T84/T85/T86 (via
#         `mk_conforme_agent`), T80 (agent-listagents), T81, T83, T87, T90, MUT-F2) — rc attendus
#         et assertions inchangés dans tous les cas.
#
# Découverte récursive (Phase 42, FABR-04, D-10, 42-06 Tâche 1) — la cible est parcourue
# récursivement (os.walk, followlinks=False), avec deux exclusions prouvées par mutation, et
# resolve_agent_name résout via la MÊME découverte (index_agents), jamais un second mécanisme :
#   T97 — récursion : `$AG/equipe/sous-agent.md` sans model + agent conforme à la racine → rc=1,
#         cite sous-agent.md et « model absent » ; le même sous-agent rendu conforme → rc=0
#   T98 — exclusions : agent conforme à la racine + `$AG/lab-references/lead-knowledge.md` (sans
#         frontmatter) + `$AG/equipe/README.md` + `$AG/.cache/x.md` → rc=0, aucun des trois cité
#   T99 — résolution : `$AG/equipe/sous-agent.md` interne (vf-internal + « Worker interne ») +
#         agent racine `tools: Read, SendMessage, Agent(sous-agent)` → rc=0 sous
#         `--resolve-agents=strict`, aucun « non resolu »
#   MUT-D1 — l'élagage des dossiers cachés remplacé par un élagage total (plus aucune descente) →
#         fixture T97 : rc_original=1, rc_mutant=0
#   MUT-D2 — l'élagage des dossiers -references neutralisé → fixture T98 : rc_original=0,
#         rc_mutant=1
#   Témoin lab frais (LAB-RECURSIF-OK, vérification externe du plan) : `.claude/agents/
#         conductor-references/*.md` posé par l'installeur reste vert sous
#         `--strict --manifest-freshness=strict`, jamais pris pour un agent.

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REAL_CHECK="$SCRIPTS_DIR/check-agents.sh"
REAL_MANIFEST="$SCRIPTS_DIR/check-agents-manifest.json"
GUARD_SRC="$SCRIPTS_DIR/guard-agent-write.sh"

# ADR-054 : meme resolution PYBIN que le gate (stub Microsoft Store, repli python).
PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*) if command -v python >/dev/null 2>&1; then PYBIN=python; else echo "[test-check-agents] python3 requis" >&2; exit 1; fi ;;
esac

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }
# okmut/komut (patron test-check-gate-touche.sh l.35-44, QUAL-01) : un mutant n'est tue que si
# les DEUX rc sont exacts — un plantage (rc inattendu) ou une derive de sortie ne comptent jamais
# comme tue, meme si un seul des deux rc matchait par accident.
okmut() {  # <id> <rc_mutant> <attendu_mut> <rc_original> <attendu_orig>
  echo "  ✓ MUT-$1 TUE : rc_mutant=$2 attendu $3, rc_original=$4 attendu $5"
  pass=$((pass+1))
}
komut() {  # <id> <assertion> <attendu> <obtenu>
  echo "  ✗ MUT-$1 NON TUE : $2"
  echo "    assertion : MUT-$1 $2"
  echo "    attendu   : $3"
  echo "    obtenu    : $4"
  fail=$((fail+1))
}

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
AG="$WORK/agents"; SK="$WORK/skills"
mkdir -p "$AG" "$SK/petit-skill" "$SK/gros-skill" "$SK/forbidden-skill"

# ---------- Manifeste daté (Phase 42, FABR-01, D-01/D-03/D-17) : harnais a manifeste du jour ----
# La suite juge la LOGIQUE du gate contre un manifeste daté DU JOUR (verifie_le recalcule a
# chaque run) — jamais contre le manifeste VERSIONNE du depot tel quel : sa fraicheur est jugee
# par la CI (42-04), jamais ici, sinon T28/T73 et consorts rougiraient a l'echeance des 30 jours.
mk_manifest() { # <destination> <age_jours> [operation]
  local dest="$1" age="$2" op="${3:-}"
  "$PYBIN" - "$REAL_MANIFEST" "$dest" "$age" "$op" <<'PYEOF'
import json, sys
from datetime import date, timedelta

real_path, dest, age_s, op = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
age = int(age_s)
with open(real_path, encoding="utf-8") as fh:
    m = json.load(fh)
verifie_le = (date.today() - timedelta(days=age)).isoformat()

if op == "tronque":
    text = json.dumps(m, indent=2, ensure_ascii=False)
    text = text[: len(text) // 2]
    with open(dest, "w", encoding="utf-8") as fh:
        fh.write(text)
    sys.exit(0)

if op != "dates-reelles":
    for liste in m["listes"].values():
        liste["verifie_le"] = verifie_le

if op in ("", "dates-reelles"):
    pass
elif op == "sans-valide-jours":
    del m["valide_jours"]
elif op.startswith("valide-jours="):
    m["valide_jours"] = json.loads(op[len("valide-jours="):])
elif op.startswith("sans-liste="):
    del m["listes"][op[len("sans-liste="):]]
elif op.startswith("liste-vide="):
    m["listes"][op[len("liste-vide="):]]["valeurs"] = []
elif op.startswith("date-invalide="):
    m["listes"][op[len("date-invalide="):]]["verifie_le"] = "23/09/2026"
elif op.startswith("date-future="):
    m["listes"][op[len("date-future="):]]["verifie_le"] = (date.today() + timedelta(days=10)).isoformat()
elif op.startswith("source-invalide="):
    m["listes"][op[len("source-invalide="):]]["source"] = "http://exemple.invalide/pas-https"
elif op == "liste-inconnue":
    m["listes"]["liste-fantome"] = {"verifie_le": verifie_le, "source": "https://exemple.invalide/x", "valeurs": ["a"]}
elif op.startswith("valeur-hors-charset="):
    cle = op[len("valeur-hors-charset="):]
    m["listes"][cle]["valeurs"] = list(m["listes"][cle]["valeurs"]) + ["valeur; interdite"]
elif op.startswith("retire="):
    cle, _, val = op[len("retire="):].partition(":")
    m["listes"][cle]["valeurs"] = [v for v in m["listes"][cle]["valeurs"] if v != val]
else:
    print(f"mk_manifest: operation inconnue '{op}'", file=sys.stderr)
    sys.exit(2)

with open(dest, "w", encoding="utf-8") as fh:
    json.dump(m, fh, indent=2, ensure_ascii=False)
PYEOF
}

mk_gate_dir() { # <dossier> <age_jours> [operation] -> imprime le chemin du dossier
  local dir="$1" age="$2" op="${3:-}"
  mkdir -p "$dir"
  cp "$REAL_CHECK" "$dir/check-agents.sh"
  cp "$GUARD_SRC" "$dir/guard-agent-write.sh"
  if [ "$op" != "absent" ]; then
    mk_manifest "$dir/check-agents-manifest.json" "$age" "$op"
  fi
  printf '%s' "$dir"
}

# make_gate_mutant <id> <age_jours> <motif-fixe> <remplacement> [operation] -> imprime le chemin
# du dossier mutant ; rc 0 = mutant opposable et syntaxiquement valide, rc 1 = refuse (deja
# comptabilise via komut). Meme discipline que make_mutant (scripts/tests/test-check-gate-touche.sh
# l.109-132) : les valeurs transitent par ENVIRON, JAMAIS par awk -v (echappement C sur \/,
# casserait toute comparaison exacte des lors que le motif porte un antislash) ; refus si la
# copie mutee est identique a l'original (cmp) ou si bash -n echoue. Le mutant vit a cote d'un
# manifeste du MEME age/operation que le run original (mk_gate_dir) : D-03 n'interfere jamais.
make_gate_mutant() { # <id> <age_jours> <motif> <remplacement> [operation]
  local id="$1" age="$2" motif="$3" remplacement="$4" op="${5:-}"
  local dir orig n tmp
  dir="$(mk_gate_dir "$WORK/mut-$id" "$age" "$op")"
  orig="$dir/check-agents.sh"
  n="$(grep -Fc -- "$motif" "$orig")"
  if [ "$n" -ne 1 ]; then
    komut "$id" "motif fixe unique dans check-agents.sh" "exactement 1 occurrence" "MOTIF AMBIGU OU ABSENT (n=$n)"
    printf '%s' "$dir"
    return 1
  fi
  tmp="$orig.mut"
  MUT_MOTIF_ENV="$motif" MUT_REPL_ENV="$remplacement" awk '
    index($0, ENVIRON["MUT_MOTIF_ENV"]) {
      match($0, /^[ \t]*/)
      print substr($0, RSTART, RLENGTH) ENVIRON["MUT_REPL_ENV"]
      next
    }
    { print }
  ' "$orig" > "$tmp"
  if cmp -s "$tmp" "$orig"; then
    komut "$id" "mutation produit un fichier different de l'original" "fichiers distincts" "NON OPPOSABLE (identique)"
    rm -f "$tmp"
    printf '%s' "$dir"
    return 1
  fi
  if ! bash -n "$tmp" 2>/dev/null; then
    komut "$id" "mutant syntaxiquement valide" "bash -n reussit" "bash -n ECHOUE"
    rm -f "$tmp"
    printf '%s' "$dir"
    return 1
  fi
  mv "$tmp" "$orig"
  printf '%s' "$dir"
  return 0
}

# juger_mutation_reelle <id> <copie-originale> <copie-mutee> <jeton> (patron T75, invariants
# I1/I4/I5/I6/I7, Phase 42 42-05) : refuse « NON OPPOSABLE » si les deux copies sont identiques
# (cmp, jamais diff — proxifie et menteur sur ce runtime) ; sinon joue le gate ($CHECK --file,
# mode PAR DEFAUT — les invariants sont des erreurs dans tous les modes, D-11) sur la copie
# mutee (attend rc=1 et le jeton dans la sortie) puis sur la copie originale (attend rc=0). Les
# deux copies vivent sous $WORK, jamais un fichier du depot modifie en place.
juger_mutation_reelle() { # <id> <orig> <mut> <jeton>
  local id="$1" orig="$2" mut="$3" jeton="$4"
  if cmp -s "$orig" "$mut"; then
    ko "$id mutation reelle NON OPPOSABLE (copies identiques, cmp) : $orig vs $mut"
    return 1
  fi
  local out_mut rc_mut out_orig rc_orig
  out_mut="$(bash "$CHECK" --file "$mut" --skills-dir="$SK" 2>&1)"; rc_mut=$?
  out_orig="$(bash "$CHECK" --file "$orig" --skills-dir="$SK" 2>&1)"; rc_orig=$?
  if [ "$rc_mut" -eq 1 ] && echo "$out_mut" | grep -q "$jeton" && [ "$rc_orig" -eq 0 ]; then
    ok "$id mutation reelle sur $(basename "$orig") : rouge ($jeton, rc=1) puis restauree → verte (rc=0)"
  else
    ko "$id (rc_mut=$rc_mut rc_orig=$rc_orig, jeton attendu='$jeton') mutant:[$out_mut] original:[$out_orig]"
  fi
}

GATE_DIR="$(mk_gate_dir "$WORK/gate" 0)"
CHECK="$GATE_DIR/check-agents.sh"
GUARD="$GATE_DIR/guard-agent-write.sh"
if [ ! -f "$GATE_DIR/check-agents-manifest.json" ]; then
  ko "harnais : manifeste du jour absent de $GATE_DIR — anti vert-a-vide"
  echo ""
  echo "== Résultat : $pass OK · $fail KO =="
  exit 1
fi

echo "== test-check-agents (gate: $CHECK) =="

printf -- '---\nname: petit-skill\ndescription: petit skill de test\n---\ncontenu court\n' > "$SK/petit-skill/SKILL.md"
{ printf -- '---\nname: gros-skill\ndescription: gros skill de test\n---\n'; for i in $(seq 1 260); do echo "ligne $i"; done; } > "$SK/gros-skill/SKILL.md"
printf -- '---\nname: forbidden-skill\ndescription: user-only\ndisable-model-invocation: true\n---\ncontenu\n' > "$SK/forbidden-skill/SKILL.md"

good_agent() {
  cat > "$AG/$1.md" <<EOF
---
name: $1
description: Pilote les tests du lab de bout en bout. Use when une suite de tests doit etre lancee ou analysee.
model: sonnet
effort: medium
memory: project
skills:
  - petit-skill
---
Corps de l agent.
EOF
}

run_check() { bash "$CHECK" --agents-dir="$AG" --skills-dir="$SK" "$@"; }

# T1 — conforme
good_agent "agent-test"
if OUT="$(run_check 2>&1)"; then ok "T1 agent complet → exit 0"; else ko "T1 rejeté : $OUT"; fi
rm -f "$AG"/*.md

# T2 — sans frontmatter
printf 'Juste du texte sans frontmatter.\n' > "$AG/nu.md"
if run_check >/dev/null 2>&1; then ko "T2 agent sans frontmatter accepté"; else ok "T2 sans frontmatter → exit 1"; fi
rm -f "$AG"/*.md

# T3 — socle manquant
printf -- '---\nname: incomplet\n---\ncorps\n' > "$AG/incomplet.md"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 1 ] && echo "$OUT" | grep -q "description" && echo "$OUT" | grep -q "model" && echo "$OUT" | grep -q "memory"; then
  ok "T3 description/model/memory manquants → 3 erreurs bloquantes"
else
  ko "T3 (rc=$RC) : $OUT"
fi
rm -f "$AG"/*.md

# T4 — enums invalides
printf -- '---\nname: enums\ndescription: agent aux enums invalides pour le test de validation\nmodel: gpt-4\nmemory: global\neffort: extreme\n---\ncorps\n' > "$AG/enums.md"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 1 ] && echo "$OUT" | grep -q "model invalide" && echo "$OUT" | grep -q "memory invalide" && echo "$OUT" | grep -q "effort invalide"; then
  ok "T4 enums invalides (model/memory/effort) → erreurs"
else
  ko "T4 (rc=$RC) : $OUT"
fi
rm -f "$AG"/*.md

# T5 — champ inconnu = warning seulement
good_agent "typo-agent"
printf -- '---\nname: typo-agent\ndescription: Agent valide avec un champ au nom errone pour tester la detection. Use when test.\nmodle: sonnet\nmodel: sonnet\neffort: medium\nmemory: project\n---\ncorps\n' > "$AG/typo-agent.md"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "champ inconnu du runtime — modle"; then
  ok "T5 champ inconnu (typo) → warning non bloquant"
else
  ko "T5 (rc=$RC) : $OUT"
fi
rm -f "$AG"/*.md

# T6 — skill introuvable : warning en défaut, erreur en strict
cat > "$AG/halluc.md" <<'EOF'
---
name: halluc
description: Agent qui declare un skill jamais cree, pour tester le gate anti-hallucination.
model: sonnet
effort: medium
memory: project
skills:
  - skill-fantome
---
corps
EOF
RC_DEF=0; run_check >/dev/null 2>&1 || RC_DEF=$?
RC_STRICT=0; run_check --strict >/dev/null 2>&1 || RC_STRICT=$?
if [ "$RC_DEF" -eq 0 ] && [ "$RC_STRICT" -eq 1 ]; then
  ok "T6 skill introuvable : warning en défaut, ERREUR en --strict"
else
  ko "T6 (défaut=$RC_DEF strict=$RC_STRICT)"
fi
rm -f "$AG"/*.md

# T7 — budget préchargement
cat > "$AG/lourd.md" <<'EOF'
---
name: lourd
description: Agent qui precharge un gros skill, pour tester le budget de prechargement.
model: sonnet
effort: medium
memory: project
skills:
  - gros-skill
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
COND1=$([ $RC -eq 0 ] && echo yes || echo no)
COND2=$(echo "$OUT" | grep -q "candidat on-demand" && echo yes || echo no)
OUT_MAX="$(VF_PRELOAD_MAX=100 run_check 2>&1)"; RC_MAX=$?
if [ "$COND1" = "yes" ] && [ "$COND2" = "yes" ] && [ $RC_MAX -eq 1 ] && echo "$OUT_MAX" | grep -q "budget de prechargement depasse"; then
  ok "T7 gros skill préchargé → warning ; cumul > VF_PRELOAD_MAX → erreur"
else
  ko "T7 (rc=$RC/$RC_MAX) : $OUT_MAX"
fi
rm -f "$AG"/*.md

# T8 — skill non préchargeable
cat > "$AG/interdit.md" <<'EOF'
---
name: interdit
description: Agent qui precharge un skill user-only, pour tester la restriction runtime.
model: sonnet
effort: medium
memory: project
skills:
  - forbidden-skill
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 1 ] && echo "$OUT" | grep -q "disable-model-invocation"; then
  ok "T8 skill disable-model-invocation préchargé → erreur"
else
  ko "T8 (rc=$RC) : $OUT"
fi
rm -f "$AG"/*.md

# T9 — hook mode
printf 'sans frontmatter\n' > "$AG/casse.md"
OUT="$(run_check --hook 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "non conforme"; then
  ok "T9 --hook : exit 0 + signalement compact"
else
  ko "T9 (rc=$RC) : $OUT"
fi
rm -f "$AG"/*.md

# T10 — contracts.md / README.md ignorés
printf 'pas un agent\n' > "$AG/contracts.md"
printf 'pas un agent\n' > "$AG/README.md"
good_agent "vrai-agent"
if run_check >/dev/null 2>&1; then ok "T10 contracts.md/README.md ignorés"; else ko "T10 fichiers non-agents lintés à tort"; fi
rm -f "$AG"/*.md

# ---------- guard-agent-write ----------
# Le guard ne s'applique qu'au LAB COURANT (CND-05) : les payloads ciblent $WORK/lab et le
# guard est exécuté avec cwd = $WORK/lab (comme le hook réel, cwd = racine du projet).
mkdir -p "$WORK/lab/.claude/agents"
payload_write() {
  # $1 = file_path · $2 = fichier contenant le content
  python3 -c "import json,sys; print(json.dumps({'tool_name':'Write','tool_input':{'file_path':sys.argv[1],'content':open(sys.argv[2]).read()}}))" "$1" "$2"
}
run_guard() { # $1 payload sur stdin — exécute le guard depuis le lab
  ( cd "$WORK/lab" && bash "$GUARD" 2>/dev/null )
}

BAD="$WORK/bad-content.md"
printf -- '---\nname: nouvel-agent\ndescription: court\n---\ncorps\n' > "$BAD"
GOOD="$WORK/good-content.md"
cat > "$GOOD" <<'EOF'
---
name: nouvel-agent
description: Analyse les ventes du lab et prepare les relances. Use when un cycle de vente demarre.
model: sonnet
effort: medium
memory: project
---
corps
EOF

OUT="$(payload_write "$WORK/lab/.claude/agents/nouvel-agent.md" "$BAD" | run_guard)"
if echo "$OUT" | grep -q '"permissionDecision": *"deny"' && echo "$OUT" | grep -q "Squelette canonique"; then
  ok "T11 Write agent non natif → deny avec squelette"
else
  ko "T11 deny attendu : ${OUT:-<vide>}"
fi

OUT="$(payload_write "$WORK/lab/.claude/agents/nouvel-agent.md" "$GOOD" | run_guard)"
[ -z "$OUT" ] && ok "T12 Write agent conforme → allow" || ko "T12 allow attendu : $OUT"

OUT1="$(payload_write "$WORK/lab/docs/note.md" "$BAD" | run_guard)"
OUT2="$(payload_write "$WORK/lab/.claude/agents/contracts.md" "$BAD" | run_guard)"
{ [ -z "$OUT1" ] && [ -z "$OUT2" ]; } && ok "T13 hors agents/ + contracts.md → allow" || ko "T13 allow attendu"

OUT="$(echo 'pas du json' | run_guard)"; RC=$?
{ [ "$RC" -eq 0 ] && [ -z "$OUT" ]; } && ok "T14 stdin invalide → fail-open" || ko "T14 fail-open (rc=$RC)"

# ---------- durcissements audit S061 (CND-01..05, CND-10) ----------

# T15 — CND-01 : frontmatter YAML quoté (parfaitement valide) → conforme
cat > "$AG/quoted.md" <<'EOF'
---
name: "quoted"
description: "Use when: un cycle de vente demarre et il faut analyser les relances du lab."
model: 'sonnet'
effort: medium
memory: "project"
---
corps
EOF
if run_check >/dev/null 2>&1; then ok "T15 scalaires YAML quotés → conforme (CND-01)"; else ko "T15 faux positif sur quotes : $(run_check 2>&1 | tail -3)"; fi
rm -f "$AG"/*.md

# T16 — CND-02 : description en plain scalar multi-ligne → conforme
cat > "$AG/multiline.md" <<'EOF'
---
name: multiline
description:
  Analyse les ventes du lab et prepare les relances commerciales.
  Use when un cycle de vente demarre ou quand un prospect relance.
model: sonnet
effort: medium
memory: project
---
corps
EOF
if run_check >/dev/null 2>&1; then ok "T16 description multi-ligne (plain scalar) → conforme (CND-02)"; else ko "T16 faux positif multi-ligne : $(run_check 2>&1 | tail -3)"; fi
rm -f "$AG"/*.md

# T17 — CND-03 : skills en chaîne plate ne contourne plus le gate --strict
cat > "$AG/chaine.md" <<'EOF'
---
name: chaine
description: Agent declarant ses skills en chaine plate, pour tester le contournement du gate.
model: sonnet
effort: medium
memory: project
skills: skill-fantome, petit-skill
---
corps
EOF
RC_STRICT=0; run_check --strict >/dev/null 2>&1 || RC_STRICT=$?
[ "$RC_STRICT" -eq 1 ] && ok "T17 skills: en chaîne + --strict → gate actif (CND-03)" || ko "T17 gate contourné (rc=$RC_STRICT)"
rm -f "$AG"/*.md

# T18 — CND-10 : BOM UTF-8 devant le frontmatter → conforme
printf '\xef\xbb\xbf' > "$AG/bom.md"
cat >> "$AG/bom.md" <<'EOF'
---
name: bom
description: Agent avec BOM UTF-8 d origine externe, pour tester la tolerance d encodage.
model: sonnet
effort: medium
memory: project
---
corps
EOF
if run_check >/dev/null 2>&1; then ok "T18 BOM UTF-8 toléré (CND-10)"; else ko "T18 faux positif BOM"; fi
rm -f "$AG"/*.md

# T19 — CND-04 : crash interne du checker → ALLOW (anti-trappe), pas un deny générique
OUT="$(payload_write "$WORK/lab/.claude/agents/nouvel-agent.md" "$GOOD" | ( cd "$WORK/lab" && VF_PRELOAD_WARN=abc bash "$GUARD" 2>/dev/null ))"
[ -z "$OUT" ] && ok "T19 checker cassé (env corrompu) → fail-open (CND-04)" || ko "T19 deny aveugle : $OUT"

# T20 — CND-05 : agent HORS du lab courant (perso user-level, autre projet) → allow
OUT="$(payload_write "$WORK/ailleurs/.claude/agents/perso.md" "$BAD" | run_guard)"
[ -z "$OUT" ] && ok "T20 agent hors lab courant → allow (CND-05)" || ko "T20 doctrine imposée hors lab : $OUT"

# T21 — F13 (vacuous green) : --strict sur cible vide → exit 3 (INDÉTERMINÉ, pas un vert)
RC=0; run_check --strict >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 3 ] && ok "T21 --strict + aucun agent → exit 3 INDÉTERMINÉ (F13)" || ko "T21 cible vide devrait sortir 3, obtenu rc=$RC"

# T22 — F13 : --strict --allow-empty sur cible vide → exit 0 (opt-in explicite)
RC=0; run_check --strict --allow-empty >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 0 ] && ok "T22 --strict --allow-empty + aucun agent → exit 0 (opt-in)" || ko "T22 --allow-empty devrait sortir 0, obtenu rc=$RC"

# T23 — compat : mode défaut (sans --strict) sur cible vide → exit 0 inchangé (labs sans agents)
RC=0; run_check >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 0 ] && ok "T23 défaut + aucun agent → exit 0 (compat labs)" || ko "T23 défaut devrait rester 0, obtenu rc=$RC"

# T24 — UAT F2 : skill déclaré par son frontmatter name: (≠ nom de dossier) → résolu en --strict
# (ex. réel : module planning-core installé sous .claude/skills/planning-core/ avec name: vf-planning)
mkdir -p "$SK/planning-core"
printf -- '---\nname: vf-planning\ndescription: socle planning du lab, name different du dossier\n---\ncontenu court\n' > "$SK/planning-core/SKILL.md"
cat > "$AG/routeur.md" <<'EOF'
---
name: routeur
description: Agent declarant un skill par son name frontmatter et non par son dossier, pour tester la resolution.
model: sonnet
effort: medium
memory: project
skills:
  - vf-planning
---
corps
EOF
RC=0; run_check --strict >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 0 ] && ok "T24 skill résolu par frontmatter name: (vf-planning → planning-core/) en --strict" || ko "T24 résolution par name: échouée (rc=$RC) : $(run_check --strict 2>&1 | tail -3)"

# T24b — un skill réellement absent (ni dossier ni name:) reste une ERREUR en --strict
cat > "$AG/routeur.md" <<'EOF'
---
name: routeur
description: Agent declarant un skill totalement inexistant, pour verifier que le gate reste actif.
model: sonnet
effort: medium
memory: project
skills:
  - skill-vraiment-fantome
---
corps
EOF
RC=0; run_check --strict >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 1 ] && ok "T24b skill inexistant (ni dossier ni name:) → toujours ERREUR en --strict" || ko "T24b gate affaibli (rc=$RC)"
rm -f "$AG"/*.md; rm -rf "$SK/planning-core"

# ---------- Phase 16 : lint des allowlists Agent(...)/Task(...) ----------

good_agent "vf-coder"
good_agent "vf-reviewer"

# T25 — allowlist reelle mixte (natif + tiers + cross-module) reste VERTE en --strict
cat > "$AG/vf-mixte.md" <<'EOF'
---
name: vf-mixte
description: Agent de test avec allowlist mixte native, tierce et cross-module, mission 16.
model: sonnet
effort: medium
memory: project
tools: Read, Write, SendMessage, Agent(vf-coder, vf-reviewer, general-purpose, gsd-planner)
---
corps
EOF
RC=0; run_check --strict >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 0 ] && ok "T25 allowlist reelle mixte --strict → exit 0" || ko "T25 (rc=$RC) : $(run_check --strict 2>&1 | tail -5)"
rm -f "$AG/vf-mixte.md"

# T26 — parenthese non fermee → exit 1 (classe syntaxe, jamais affectee par --strict)
cat > "$AG/nonferme.md" <<'EOF'
---
name: nonferme
description: Agent de test avec une allowlist Agent a parenthese non fermee.
model: sonnet
effort: medium
memory: project
tools: Read, Agent(vf-coder
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "parenthese non fermee"; then
  ok "T26 parenthese non fermee → exit 1 (citee dans le message)"
else
  ko "T26 (rc=$RC) : $OUT"
fi
rm -f "$AG/nonferme.md"

# T27 — Agent() vide → exit 1
cat > "$AG/vide.md" <<'EOF'
---
name: vide
description: Agent de test declarant une allowlist Agent totalement vide.
model: sonnet
effort: medium
memory: project
tools: Read, Agent()
---
corps
EOF
RC=0; run_check >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 1 ] && ok "T27 Agent() vide → exit 1" || ko "T27 (rc=$RC)"
rm -f "$AG/vide.md"

# T28 — outil hors set connu (Reed) : warning en defaut, ERREUR en --strict ; Read reste vert
cat > "$AG/reed.md" <<'EOF'
---
name: reed
description: Agent de test declarant l'outil Reed (typo) au lieu de Read.
model: sonnet
effort: medium
memory: project
tools: Reed, SendMessage, Agent(vf-coder)
---
corps
EOF
OUT_DEF="$(run_check 2>&1)"; RC_DEF=$?
RC_STRICT=0; run_check --strict >/dev/null 2>&1 || RC_STRICT=$?
if [ "$RC_DEF" -eq 0 ] && echo "$OUT_DEF" | grep -qi "outil hors" && [ "$RC_STRICT" -eq 1 ]; then
  ok "T28 Reed : warning en defaut, ERREUR en --strict"
else
  ko "T28 (def=$RC_DEF strict=$RC_STRICT) : $OUT_DEF"
fi
rm -f "$AG/reed.md"
cat > "$AG/lu.md" <<'EOF'
---
name: lu
description: Agent de test avec l'outil Read correctement orthographie, non-regression.
model: sonnet
effort: medium
memory: project
tools: Read, SendMessage, Agent(vf-coder)
disallowedTools: Write, Edit
---
corps
EOF
RC_DEF=0; run_check >/dev/null 2>&1 || RC_DEF=$?
RC_STRICT=0; run_check --strict >/dev/null 2>&1 || RC_STRICT=$?
[ "$RC_DEF" -eq 0 ] && [ "$RC_STRICT" -eq 0 ] && ok "T28b Read (bien orthographie) reste vert (defaut+strict)" || ko "T28b (def=$RC_DEF strict=$RC_STRICT)"
rm -f "$AG/lu.md"

# T29 — Agent(vf-codeur) (typo de nom d'agent) reste VERT meme en --strict — non-regression
# faux positif : c'est le test le plus important de la serie (cf. digest de mission).
cat > "$AG/typo-nom.md" <<'EOF'
---
name: typo-nom
description: Agent de test declarant un nom d'agent mal orthographie dans son allowlist.
model: sonnet
effort: medium
memory: project
tools: Read, SendMessage, Agent(vf-codeur)
disallowedTools: Write, Edit
---
corps
EOF
OUT="$(run_check --strict 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -qi "nom d'agent non resolu"; then
  ok "T29 Agent(vf-codeur) (typo) reste VERT en --strict, avec warning"
else
  ko "T29 (rc=$RC) : $OUT"
fi

# T30 — le MEME mutant (vf-codeur) sous --resolve-agents=strict + registre → exit 1 ;
# vf-coder (nom correct, fichier present) reste vert sous la meme resolution stricte.
REG="$WORK/registry"; mkdir -p "$REG"
cp "$AG/vf-coder.md" "$REG/vf-coder.md"
RC=0; run_check --resolve-agents=strict --agent-registry-dir="$REG" >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 1 ] && ok "T30 vf-codeur (typo) sous --resolve-agents=strict → exit 1 (discriminance prouvee)" || ko "T30 (rc=$RC)"
rm -f "$AG/typo-nom.md"
cat > "$AG/nom-ok.md" <<'EOF'
---
name: nom-ok
description: Agent de test avec un nom d'agent correctement resolu via le registre.
model: sonnet
effort: medium
memory: project
tools: Read, SendMessage, Agent(vf-coder)
---
corps
EOF
RC=0; run_check --resolve-agents=strict --agent-registry-dir="$REG" >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 0 ] && ok "T30b vf-coder (resolu) reste vert sous --resolve-agents=strict" || ko "T30b (rc=$RC)"
rm -f "$AG/nom-ok.md"

# T31 — flow list YAML non dechiquetee : [Read, Agent(x, y), Bash(git:*)] → 0 finding fantome
cat > "$AG/flow.md" <<'EOF'
---
name: flow
description: Agent de test declarant son allowlist en flow list YAML entre crochets.
model: sonnet
effort: medium
memory: project
tools: [Read, SendMessage, Agent(x, y), Bash(git:*)]
disallowedTools: Write, Edit
---
corps
EOF
OUT="$(run_check --strict 2>&1)"; RC=$?
# Assertion forte (pas seulement l'absence d'un message precis) : avec un split naif (mutant
# teste manuellement), "Agent(x" et " y)" deviennent des tokens invalides (parenthese non
# fermee / token hors charset) -> exit 1 meme en mode defaut. Avec le tokenizer a profondeur
# de parentheses, exactement 3 tokens valides (Read, Agent(x,y), Bash(git:*)) -> --strict reste
# vert (x/y non resolus restent des WARNINGS, jamais des ERREURS sous --strict seul).
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -qE "hors charset|parenthese non fermee|hors du set connu 'Agent'"; then
  ok "T31 flow list [Read, Agent(x, y), Bash(git:*)] → --strict reste vert, aucun finding fantome"
else
  ko "T31 flow list dechiquetee (rc=$RC) : $OUT"
fi
rm -f "$AG/flow.md"

# T32 — prefixe tiers : un agent gsd-planner.md sans model/memory est ignore par defaut,
# et redevient linte (donc en erreur) des --no-third-party-prefix (solde CONCERNS.md:52-59).
cat > "$AG/gsd-planner.md" <<'EOF'
---
name: gsd-planner
description: Agent tiers GSD sans model ni memory, pour tester le skip par prefixe.
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "fichier(s) agent tiers non linte"; then
  ok "T32 gsd-planner (tiers, prefixe gsd- par defaut) → ignore, exit 0"
else
  ko "T32 (rc=$RC) : $OUT"
fi
RC=0; run_check --no-third-party-prefix >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 1 ] && ok "T32b --no-third-party-prefix → gsd-planner linte normalement → exit 1" || ko "T32b (rc=$RC)"
rm -f "$AG/gsd-planner.md"

# T33 — Task(...) alias legacy (Claude Code v2.1.63) reste vert, traite comme Agent(...)
cat > "$AG/taskalias.md" <<'EOF'
---
name: taskalias
description: Agent de test utilisant l'alias legacy Task au lieu d'Agent dans tools.
model: sonnet
effort: medium
memory: project
tools: Read, SendMessage, Task(vf-coder)
disallowedTools: Write, Edit
---
corps
EOF
RC=0; run_check --strict >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 0 ] && ok "T33 Task(vf-coder) (alias legacy) reste vert" || ko "T33 (rc=$RC) : $(run_check --strict 2>&1 | tail -5)"
rm -f "$AG/taskalias.md"

# T34 — Agent nu (sans allowlist parenthesee) → warning non bloquant "dispatch non cloisonne"
cat > "$AG/nu-agent.md" <<'EOF'
---
name: nu-agent
description: Agent de test declarant Agent sans aucune allowlist parenthesee.
model: sonnet
effort: medium
memory: project
tools: Read, Agent
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "dispatch non cloisonne"; then
  ok "T34 Agent nu → warning non bloquant"
else
  ko "T34 (rc=$RC) : $OUT"
fi
rm -f "$AG"/*.md

# ---------- Correctifs post-revue (re-entree Phase 16, 2 juges independants) ----------

good_agent "vf-coder"

# T35 — defaut 1 : champ tools: ENTIEREMENT quote (YAML valide) ne doit plus produire de
# faux BLOQUANT (charset / parenthese non fermee sur les guillemets eux-memes).
cat > "$AG/quote-tools.md" <<'EOF'
---
name: quote-tools
description: Agent de test avec un champ tools entierement quote entre guillemets.
model: sonnet
effort: medium
memory: project
tools: "Read, Write, SendMessage, Agent(vf-coder)"
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -qE "hors charset|parenthese non fermee"; then
  ok "T35 tools: entierement quote → conforme, aucun faux BLOQUANT (defaut 1)"
else
  ko "T35 (rc=$RC) : $OUT"
fi
rm -f "$AG/quote-tools.md"

# T36 — defaut 2 : ligne vide au milieu d'une liste bloc tools: ne doit plus faire perdre
# silencieusement les puces suivantes. Verifie via --resolve-agents=strict (discriminance
# forte : avant le correctif, exit 0 total silence ; apres, exit 1 sur l'entree recuperee).
cat > "$AG/blank-block.md" <<'EOF'
---
name: blank-block
description: Agent de test avec une ligne vide au milieu d'une liste bloc tools.
model: sonnet
effort: medium
memory: project
tools:
  - Read
  - SendMessage

  - Agent(vf-inexistant-improvise)
---
corps
EOF
OUT_DEF="$(run_check 2>&1)"; RC_DEF=$?
RC_STRICTRES=0; run_check --resolve-agents=strict >/dev/null 2>&1 || RC_STRICTRES=$?
if [ "$RC_DEF" -eq 0 ] && echo "$OUT_DEF" | grep -q "vf-inexistant-improvise" && [ "$RC_STRICTRES" -eq 1 ]; then
  ok "T36 ligne vide dans liste bloc → puce suivante recuperee (warning + erreur sous strict) (defaut 2)"
else
  ko "T36 (def=$RC_DEF strictres=$RC_STRICTRES) : $OUT_DEF"
fi
rm -f "$AG/blank-block.md"

# T37 — defaut 3 : parenthese EN TROP 'Agent(a))' → exit 1. Pinne SPECIFIQUEMENT split_depth
# (seul detecteur du depth < 0) : analyze_token ne catche pas ce cas (rest se termine bien
# par ')'), donc ce test tombe si on mute 'depth != 0' en 'depth > 0' dans split_depth.
cat > "$AG/extra-paren.md" <<'EOF'
---
name: extra-paren
description: Agent de test avec une parenthese fermante en trop dans une allowlist.
model: sonnet
effort: medium
memory: project
tools: Read, Agent(a))
---
corps
EOF
RC=0; run_check >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 1 ] && ok "T37 parenthese en trop 'Agent(a))' → exit 1 (pinne split_depth, defaut 3)" || ko "T37 (rc=$RC)"
rm -f "$AG/extra-paren.md"

# T38 — entree vide au niveau token (virgule orpheline) → exit 1
cat > "$AG/orpheline.md" <<'EOF'
---
name: orpheline
description: Agent de test avec une virgule orpheline produisant une entree vide.
model: sonnet
effort: medium
memory: project
tools: Read,,Agent(x)
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "entree d'allowlist vide"; then
  ok "T38 virgule orpheline 'Read,,Agent(x)' → exit 1"
else
  ko "T38 (rc=$RC) : $OUT"
fi
rm -f "$AG/orpheline.md"

# T39 — entree vide A L'INTERIEUR d'une allowlist → exit 1
cat > "$AG/interne-vide.md" <<'EOF'
---
name: interne-vide
description: Agent de test avec une entree vide a l'interieur d'une allowlist Agent.
model: sonnet
effort: medium
memory: project
tools: Agent(a,,b)
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "entree vide dans l'allowlist"; then
  ok "T39 'Agent(a,,b)' (entree vide interne) → exit 1"
else
  ko "T39 (rc=$RC) : $OUT"
fi
rm -f "$AG/interne-vide.md"

# T40 — espace avant la parenthese → exit 1
cat > "$AG/espace-paren.md" <<'EOF'
---
name: espace-paren
description: Agent de test avec un espace entre le nom de l'outil et la parenthese.
model: sonnet
effort: medium
memory: project
tools: Read, Agent (vf-coder)
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "espace avant la parenthese"; then
  ok "T40 'Agent (vf-coder)' (espace avant parenthese) → exit 1"
else
  ko "T40 (rc=$RC) : $OUT"
fi
rm -f "$AG/espace-paren.md"

# T41 — token hors charset au niveau bare (sans parenthese, ex. symbole non autorise)
cat > "$AG/bare-charset.md" <<'EOF'
---
name: bare-charset
description: Agent de test avec un token bare contenant un caractere hors charset.
model: sonnet
effort: medium
memory: project
tools: Read, Bash@2
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "token hors charset"; then
  ok "T41 token bare hors charset ('Bash@2') → exit 1"
else
  ko "T41 (rc=$RC) : $OUT"
fi
rm -f "$AG/bare-charset.md"

# T42 — name invalide (majuscules/espaces, hors [a-z0-9-])
cat > "$AG/nom-invalide.md" <<'EOF'
---
name: "Nom Invalide"
description: Agent de test dont le name contient des majuscules et un espace.
model: sonnet
effort: medium
memory: project
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "name invalide"; then
  ok "T42 name invalide (majuscules/espaces) → exit 1"
else
  ko "T42 (rc=$RC) : $OUT"
fi
rm -f "$AG/nom-invalide.md"

# T43 — permissionMode invalide
cat > "$AG/permmode.md" <<'EOF'
---
name: permmode
description: Agent de test avec un permissionMode qui n'existe pas dans l'enum attendu.
model: sonnet
effort: medium
memory: project
permissionMode: yolo
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "permissionMode invalide"; then
  ok "T43 permissionMode invalide → exit 1"
else
  ko "T43 (rc=$RC) : $OUT"
fi
rm -f "$AG/permmode.md"

# T44 — isolation invalide (seul 'worktree' est admis)
cat > "$AG/isol.md" <<'EOF'
---
name: isol
description: Agent de test avec une valeur isolation qui n'est pas worktree.
model: sonnet
effort: medium
memory: project
isolation: sandbox
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "isolation invalide"; then
  ok "T44 isolation invalide → exit 1"
else
  ko "T44 (rc=$RC) : $OUT"
fi
rm -f "$AG/isol.md"

# T45 — background invalide (attendu true|false)
cat > "$AG/bg.md" <<'EOF'
---
name: bg
description: Agent de test avec un champ background qui n'est ni true ni false.
model: sonnet
effort: medium
memory: project
background: maybe
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "background invalide"; then
  ok "T45 background invalide → exit 1"
else
  ko "T45 (rc=$RC) : $OUT"
fi
rm -f "$AG/bg.md"

# T46 — maxTurns invalide (attendu un entier)
cat > "$AG/maxt.md" <<'EOF'
---
name: maxt
description: Agent de test avec un champ maxTurns qui n'est pas un entier valide.
model: sonnet
effort: medium
memory: project
maxTurns: beaucoup
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "maxTurns invalide"; then
  ok "T46 maxTurns invalide → exit 1"
else
  ko "T46 (rc=$RC) : $OUT"
fi
rm -f "$AG/maxt.md"

# T47 — skills absent → warning non bloquant (pas d'ERREUR meme en --strict, hors resolution)
cat > "$AG/sans-skill.md" <<'EOF'
---
name: sans-skill
description: Agent de test sans aucun champ skills declare, pour verifier le warning.
model: sonnet
effort: medium
memory: project
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "aucun skill cable"; then
  ok "T47 skills absent → warning non bloquant"
else
  ko "T47 (rc=$RC) : $OUT"
fi
rm -f "$AG/sans-skill.md"

# T48 — description < 30 caracteres → warning non bloquant
cat > "$AG/desc-courte.md" <<'EOF'
---
name: desc-courte
description: trop court
model: sonnet
effort: medium
memory: project
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "description trop courte"; then
  ok "T48 description < 30c → warning non bloquant"
else
  ko "T48 (rc=$RC) : $OUT"
fi
rm -f "$AG/desc-courte.md"

# T49 — tools absent → warning non bloquant (herite tout)
cat > "$AG/sans-tools.md" <<'EOF'
---
name: sans-tools
description: Agent de test sans champ tools declare, pour verifier le warning d'heritage.
model: sonnet
effort: medium
memory: project
skills:
  - petit-skill
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "tools absent"; then
  ok "T49 tools absent → warning non bloquant (herite tout)"
else
  ko "T49 (rc=$RC) : $OUT"
fi
rm -f "$AG/sans-tools.md"

# T50 — name different du nom de fichier → warning non bloquant
cat > "$AG/autre-fichier.md" <<'EOF'
---
name: nom-different
description: Agent de test dont le name ne correspond pas au nom du fichier sur disque.
model: sonnet
effort: medium
memory: project
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "different du nom de fichier"; then
  ok "T50 name ≠ nom de fichier → warning non bloquant"
else
  ko "T50 (rc=$RC) : $OUT"
fi
rm -f "$AG/autre-fichier.md" "$AG/vf-coder.md"

# ---------- Gate final (3 ecarts en-tete <-> comportement, re-entree Phase 16 exec-lint) ----------

# T51 — --resolve-agents=<valeur invalide> (typo type 'stricts') → exit 1 explicite. Avant le
# correctif, le code ne testait que '== "strict"' : toute autre valeur (y compris une typo CI)
# degradait SILENCIEUSEMENT en lenient, exit 0, aucun message — exactement le faux vert F13
# que ce script interdit deja pour la cible vide. Discriminance : ce test tombe (exit 0, pas
# de message) si on mute la validation en retirant le case lenient|strict.
RC=0; OUT="$(run_check --resolve-agents=stricts 2>&1)" || RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "resolve-agents invalide"; then
  ok "T51 --resolve-agents=stricts (typo) → exit 1 explicite (plus un skip muet)"
else
  ko "T51 (rc=$RC) : $OUT"
fi

# T52 — --third-party-prefix ACCUMULE au-dessus du defaut gsd- (ne l'ecrase plus). Avant le
# correctif, la premiere occurrence videait THIRD_PARTY_PREFIXES avant d'ajouter la valeur
# custom : gsd-planner.md redevenait linte (donc en erreur) des qu'un seul --third-party-prefix
# etait fourni, meme sans --no-third-party-prefix. Discriminance : ce test tombe (rc=1, ou
# 'prefixe(s) : acme-' sans 'gsd-') si on remet l'ecrasement au premier flag custom.
cat > "$AG/gsd-planner.md" <<'EOF'
---
name: gsd-planner
description: Agent tiers GSD sans model ni memory, pour tester l'accumulation de prefixe.
---
corps
EOF
RC=0; OUT="$(run_check --third-party-prefix=acme- 2>&1)" || RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "prefixe(s) : gsd-,acme-"; then
  ok "T52 --third-party-prefix=acme- ACCUMULE sur le defaut gsd- (gsd-planner toujours ignore)"
else
  ko "T52 (rc=$RC) : $OUT"
fi
rm -f "$AG/gsd-planner.md"

# T53 — compteurs DISTINCTS : fichiers agent tiers non lintes != entrees d'allowlist tierces
# resolues. Avant le correctif, un seul compteur amalgamait les deux populations sous le
# libelle trompeur 'N agent(s) tiers ignore(s)' (33 sur dev-orchestrator alors que 0 fichier
# gsd-*.md n'existait sur disque). Ici : 2 fichiers tiers + 1 entree d'allowlist tierce (jamais
# materialisee en fichier) doivent produire deux chiffres differents et correctement libelles.
cat > "$AG/gsd-other.md" <<'EOF'
---
name: gsd-other
description: Premier agent tiers GSD, pour peupler le compteur de fichiers non lintes.
---
corps
EOF
cat > "$AG/gsd-other2.md" <<'EOF'
---
name: gsd-other2
description: Second agent tiers GSD, pour peupler le compteur de fichiers non lintes.
---
corps
EOF
cat > "$AG/vf-mixte2.md" <<'EOF'
---
name: vf-mixte2
description: Agent de test dont l'allowlist reference un agent tiers jamais materialise sur disque.
model: sonnet
effort: medium
memory: project
tools: Read, SendMessage, Agent(gsd-jamais-cree)
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "2 fichier(s) agent tiers non linte(s) · 1 entree(s) d'allowlist tierce(s) resolue(s)"; then
  ok "T53 compteurs distincts : 2 fichier(s) agent tiers != 1 entree(s) d'allowlist tierce(s)"
else
  ko "T53 (rc=$RC) : $OUT"
fi
rm -f "$AG/gsd-other.md" "$AG/gsd-other2.md" "$AG/vf-mixte2.md"

# T54 (nit) — 'Agent(a))' (parenthese fermante EN TROP, pas manquante) ne doit plus etre
# libelle 'non fermee' (message pointant vers l'oppose du vrai probleme). Discriminance :
# ce test tombe si on refusionne les deux branches de signe en un seul message 'non fermee'.
cat > "$AG/extra-mot.md" <<'EOF'
---
name: extra-mot
description: Agent de test pour verifier le libelle exact de la parenthese en trop.
model: sonnet
effort: medium
memory: project
tools: Read, Agent(a))
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "fermante en trop" && ! echo "$OUT" | grep -q "parenthese non fermee"; then
  ok "T54 'Agent(a))' → libelle 'fermante en trop' distinct de 'non fermee' (nit)"
else
  ko "T54 (rc=$RC) : $OUT"
fi
rm -f "$AG/extra-mot.md"

# ---------- Chemin par DEFAUT des gates (D-24) — jamais exerce jusqu'ici ----------
# Aucun des 54 cas precedents n'invoque check-agents.sh SANS --agents-dir/--skills-dir : le helper
# d'invocation partage par tous les cas ci-dessus les injecte systematiquement en dur. C'est ce
# point aveugle qui a laisse un defaut de perimetre (AGENTS_DIR/SKILLS_DIR resolus depuis le cwd du
# hook, jamais celui du plugin) survivre a toute la Phase 16. Les 3 cas suivants invoquent
# bash "$CHECK" DIRECTEMENT, dans un sous-shell deplace vers un repertoire factice mktemp -d, sans
# jamais toucher au cwd de la suite elle-meme. Mutation tuee : alterer la valeur par defaut
# AGENTS_DIR (ou SKILLS_DIR) dans check-agents.sh fait echouer T57 — la sonde qui manquait
# (T55/T56 passeraient encore avec un defaut casse, T57 seul le prouve).

PWD_BEFORE="$(pwd)"

# T55 — cible absente, mode strict : exit 3 INDETERMINE, jamais un vert (contrat F13 / D-24)
DEFAULT_EMPTY="$(mktemp -d)"
OUT="$(cd "$DEFAULT_EMPTY" && bash "$CHECK" --strict 2>&1)"; RC=$?
if [ "$RC" -eq 3 ] && echo "$OUT" | grep -q "INDETERMINE"; then
  ok "T55 chemin par defaut, cible absente, --strict → exit 3 INDÉTERMINÉ, jamais un vert (D-24)"
else
  ko "T55 (rc=$RC) : $OUT"
fi
rm -rf "$DEFAULT_EMPTY"

# T56 — cible absente, mode hook : exit 0, silence TOTAL (pin de l'exemption volontaire sur
# cible vide — une suppression inconditionnelle future de cette exemption ferait echouer ce cas)
DEFAULT_EMPTY2="$(mktemp -d)"
OUT="$(cd "$DEFAULT_EMPTY2" && bash "$CHECK" --hook 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "T56 chemin par defaut, cible absente, --hook → exit 0, silence total (exemption pinnee)"
else
  ko "T56 (rc=$RC) : '$OUT'"
fi
rm -rf "$DEFAULT_EMPTY2"

# T57 — cible PRESENTE au chemin par defaut, cas DISCRIMINANT : seul ce cas prouve que la valeur
# par defaut resout une cible reelle — T55/T56 passeraient encore avec un defaut casse (pointant
# vers un repertoire qui n'existera jamais).
DEFAULT_PRESENT="$(mktemp -d)"
mkdir -p "$DEFAULT_PRESENT/.claude/agents"
printf 'Aucun frontmatter ici -- non conforme.\n' > "$DEFAULT_PRESENT/.claude/agents/casse.md"
RC=0; (cd "$DEFAULT_PRESENT" && bash "$CHECK") >/dev/null 2>&1 || RC=$?
if [ "$RC" -eq 1 ]; then
  ok "T57 chemin par defaut, cible presente non conforme, SANS flag → exit 1 (le defaut resout une cible reelle)"
else
  ko "T57 (rc=$RC) — le defaut AGENTS_DIR ne resout pas la cible reelle"
fi
rm -rf "$DEFAULT_PRESENT"

# T58 — le cwd de la suite est inchange : les 3 deplacements ci-dessus sont confines a des sous-shells
[ "$(pwd)" = "$PWD_BEFORE" ] && ok "T58 cwd de la suite inchange apres les cas chemin par defaut" || ko "T58 cwd altere : $(pwd) != $PWD_BEFORE"

# T103 — invocation NUE sur cible ABSENTE, hors --hook (Phase 42, D-20, CONCERNS.md:349) : le
# faux vert historique (exit 0 "rien a verifier") devient INDETERMINE (exit 3, CIBLE-ABSENTE).
T103_ABSENT="$(mktemp -d)"
OUT="$(cd "$T103_ABSENT" && bash "$CHECK" 2>&1)"; RC=$?
if [ "$RC" -eq 3 ] && echo "$OUT" | grep -q "INDETERMINE" && echo "$OUT" | grep -q "CIBLE-ABSENTE"; then
  ok "T103 invocation nue, cible absente, hors --hook → rc=3 INDÉTERMINÉ, jeton CIBLE-ABSENTE (D-20)"
else
  ko "T103 (rc=$RC) : $OUT"
fi
rm -rf "$T103_ABSENT"

# T103 (jumeau vert) — meme invocation nue, mais .claude/agents PRESENT et VIDE : regime F13
# deja en place (T23), CIBLE-ABSENTE ne doit JAMAIS apparaitre.
T103_PRESENT_VIDE="$(mktemp -d)"
mkdir -p "$T103_PRESENT_VIDE/.claude/agents"
OUT="$(cd "$T103_PRESENT_VIDE" && bash "$CHECK" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "CIBLE-ABSENTE"; then
  ok "T103 (jumeau vert) invocation nue, .claude/agents présent et vide → rc=0, jamais CIBLE-ABSENTE (régime T23 inchangé)"
else
  ko "T103 (jumeau vert, rc=$RC) : $OUT"
fi
rm -rf "$T103_PRESENT_VIDE"

# ---------- D-18/D-19 (perimetre hooks.json, hors perimetre de CE script) + D-21/D-22/D-05 ----------

# T59 — hook, 0 erreur 0 avertissement → silence total (regime nominal inchange)
cat > "$AG/silencieux.md" <<'EOF'
---
name: silencieux
description: Agent de test entierement conforme, aucun avertissement attendu ici.
model: sonnet
effort: medium
memory: project
tools: Read
disallowedTools: Write, Edit
omitClaudeMd: true
skills:
  - petit-skill
---
corps
EOF
OUT="$(run_check --hook 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "T59 hook, 0 erreur 0 avertissement → silence total (D-21)"
else
  ko "T59 (rc=$RC) : '$OUT'"
fi
rm -f "$AG/silencieux.md"

# T60 — hook, 0 erreur >= 1 avertissement → ligne compacte avec compte + invocation explicite
cat > "$AG/avec-warning.md" <<'EOF'
---
name: avec-warning
description: Agent de test avec un champ inconnu, pour verifier le resume hook (D-21).
modle: sonnet
model: sonnet
effort: medium
memory: project
tools: Read
---
corps
EOF
OUT="$(run_check --hook 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -qE "avertissement" && echo "$OUT" | grep -q "bash .claude/scripts/check-agents.sh"; then
  ok "T60 hook, 0 erreur >=1 avertissement → ligne compacte compte + renvoi vers l'invocation explicite (D-21)"
else
  ko "T60 (rc=$RC) : $OUT"
fi
rm -f "$AG/avec-warning.md"

# T61 — hook, >=1 erreur → sortie inchangee (les erreurs priment, aucun resume d'avertissements mele)
printf 'sans frontmatter\n' > "$AG/casse2.md"
OUT="$(run_check --hook 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "non conforme" && ! echo "$OUT" | grep -q "avertissement"; then
  ok "T61 hook, >=1 erreur → sortie inchangee, pas de resume avertissements mele (D-21)"
else
  ko "T61 (rc=$RC) : $OUT"
fi
rm -f "$AG/casse2.md"

# T62-T66 — charset d'un token MCP a joker TERMINAL (D-22)
mk_mcp_agent() { # $1 nom fichier, $2 valeur additionnelle de tools
  cat > "$AG/$1.md" <<EOF
---
name: $1
description: Agent de test MCP pour verifier le charset du joker terminal (D-22).
model: sonnet
effort: medium
memory: project
tools: Read, $2
disallowedTools: Write, Edit
omitClaudeMd: true
---
corps
EOF
}

mk_mcp_agent "mcp-ok1" "mcp__XcodeBuildMCP__*"
RC=0; run_check --strict >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 0 ] && ok "T62 tools: mcp__XcodeBuildMCP__* (joker terminal) → accepte (D-22)" || ko "T62 (rc=$RC)"
rm -f "$AG/mcp-ok1.md"

mk_mcp_agent "mcp-ok2" "mcp__XcodeBuildMCP__test_sim"
RC=0; run_check --strict >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 0 ] && ok "T63 tools: mcp__XcodeBuildMCP__test_sim (deja accepte avant D-22) → non-regression" || ko "T63 (rc=$RC)"
rm -f "$AG/mcp-ok2.md"

mk_mcp_agent "mcp-bad1" "mcp__*"
RC=0; run_check >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 1 ] && ok "T64 tools: mcp__* (joker seul, sans serveur) → rejete (D-22)" || ko "T64 (rc=$RC)"
rm -f "$AG/mcp-bad1.md"

mk_mcp_agent "mcp-bad2" "mcp__XcodeBuildMCP__*_sim"
RC=0; run_check >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 1 ] && ok "T65 tools: mcp__XcodeBuildMCP__*_sim (joker NON terminal) → rejete (D-22)" || ko "T65 (rc=$RC)"
rm -f "$AG/mcp-bad2.md"

mk_mcp_agent "mcp-bad3" "mcp__Xcode*MCP__*"
RC=0; run_check >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 1 ] && ok "T66 tools: mcp__Xcode*MCP__* (joker dans le nom de serveur) → rejete (D-22)" || ko "T66 (rc=$RC)"
rm -f "$AG/mcp-bad3.md"

# T67-T68 — la clef de frontmatter vf-mcp-tools devient connue du gate (D-05)
cat > "$AG/mcp-tools-ok.md" <<'EOF'
---
name: mcp-tools-ok
description: Agent de test declarant vf-mcp-tools, pour verifier que la clef est connue (D-05).
model: sonnet
effort: medium
memory: project
tools: Read
disallowedTools: Write, Edit
omitClaudeMd: true
vf-mcp-tools: XcodeBuildMCP:test_sim,build_sim,clean
vf-requires: mcp-servers
---
corps
EOF
OUT="$(run_check --strict 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "champ inconnu du runtime — vf-mcp-tools"; then
  ok "T67 vf-mcp-tools (clef exacte) → aucun avertissement de champ inconnu, --strict exit 0 (D-05)"
else
  ko "T67 (rc=$RC) : $OUT"
fi
rm -f "$AG/mcp-tools-ok.md"

cat > "$AG/mcp-tools-typo.md" <<'EOF'
---
name: mcp-tools-typo
description: Agent de test avec une typo de vf-mcp-tools, pour verifier que le gate reste actif.
model: sonnet
effort: medium
memory: project
tools: Read
vf-mcp-tool: XcodeBuildMCP:test_sim
vf-requires: mcp-servers
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "champ inconnu du runtime — vf-mcp-tool"; then
  ok "T68 typo de vf-mcp-tools ('vf-mcp-tool') → avertissement de champ inconnu toujours declenche"
else
  ko "T68 (rc=$RC) : $OUT"
fi
rm -f "$AG/mcp-tools-typo.md"

# ---------- Extension : memory: + tools: sans Write/Edit exige disallowedTools (anti-regression) ----------

# T69 — agent memory: + tools: sans Write/Edit, SANS disallowedTools → warning en defaut, ERREUR en --strict
cat > "$AG/juge-sans-barriere.md" <<'EOF'
---
name: juge-sans-barriere
description: Agent de test qui omet Write/Edit de tools sans les fermer via disallowedTools.
model: sonnet
effort: medium
memory: project
tools: Read, Bash
---
corps
EOF
OUT_DEF="$(run_check 2>&1)"; RC_DEF=$?
RC_STRICT=0; run_check --strict >/dev/null 2>&1 || RC_STRICT=$?
if [ "$RC_DEF" -eq 0 ] && echo "$OUT_DEF" | grep -q "exige disallowedTools: Write, Edit" && [ "$RC_STRICT" -eq 1 ]; then
  ok "T69 memory:+tools: sans Write/Edit, sans disallowedTools → warning en defaut, ERREUR en --strict (anti-regression)"
else
  ko "T69 (def=$RC_DEF strict=$RC_STRICT) : $OUT_DEF"
fi
rm -f "$AG/juge-sans-barriere.md"

# T70 — la MEME situation, disallowedTools: Write, Edit pose → silence total, --strict exit 0
cat > "$AG/juge-avec-barriere.md" <<'EOF'
---
name: juge-avec-barriere
description: Agent de test qui ferme explicitement Write/Edit via disallowedTools.
model: sonnet
effort: medium
memory: project
tools: Read, Bash
disallowedTools: Write, Edit
omitClaudeMd: true
---
corps
EOF
OUT="$(run_check --strict 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "exige disallowedTools"; then
  ok "T70 memory:+tools: sans Write/Edit MAIS disallowedTools: Write, Edit pose → conforme, --strict exit 0"
else
  ko "T70 (rc=$RC) : $OUT"
fi
rm -f "$AG/juge-avec-barriere.md"

# T71 — non-regression : un agent dont tools: INCLUT deja Write/Edit reste silencieux (pas de fausse alerte)
cat > "$AG/producteur.md" <<'EOF'
---
name: producteur
description: Agent de test dont tools inclut deja Write, pour verifier l'absence de faux positif.
model: sonnet
effort: medium
memory: project
tools: Read, Write, Edit, Bash
---
corps
EOF
OUT="$(run_check --strict 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "exige disallowedTools"; then
  ok "T71 tools: inclut deja Write/Edit → aucune fausse alerte de la regle anti-regression"
else
  ko "T71 (rc=$RC) : $OUT"
fi
rm -f "$AG/producteur.md"

# ---------- T73/T74/T75 : effort: EXIGE (zone 6, Phase 24 — GSDA-20/21) ----------
# Le champ effort: etait valide S'IL ETAIT PRESENT (une seule branche : valeur hors enum).
# Un agent qui l'omettait passait le gate en silence — donc 0 des 25 agents livres le portait.
# Le durcissement transpose le patron du bloc model: (absence = ERREUR, puis validation de
# valeur). Les trois cas ci-dessous bornent ce durcissement des deux cotes.

# T73 — agent LOCAL complet (name/description/model/memory) mais SANS effort: → erreur nommant effort
cat > "$AG/sans-effort.md" <<'EOF'
---
name: sans-effort
description: Agent local complet sur le socle natif mais qui omet le champ effort, pour tester l'exigence.
model: sonnet
memory: project
skills:
  - petit-skill
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "effort absent" && echo "$OUT" | grep -q "low|medium|high|xhigh|max"; then
  ok "T73 agent local sans effort: → ERREUR bloquante nommant effort et ses valeurs admises"
else
  ko "T73 (rc=$RC) : $OUT"
fi
rm -f "$AG/sans-effort.md"

# T73b — COHERENCE du message de refus : guard-agent-write.sh refuse desormais un agent sans
# effort:, et son squelette canonique annoncait "effort: <optionnel>". Un refus qui declare
# optionnel le champ pour l'absence duquel il refuse est pire qu'un refus muet — l'auteur
# corrige tout SAUF la cause. Le squelette doit enumerer les valeurs, jamais dire optionnel.
OUT="$(payload_write "$WORK/lab/.claude/agents/nouvel-agent.md" "$BAD" | run_guard)"
if echo "$OUT" | grep -q "effort: low|medium|high|xhigh|max" && ! echo "$OUT" | grep -q "effort: <optionnel>"; then
  ok "T73b squelette du guard : effort enumere comme requis, plus annonce optionnel"
else
  ko "T73b : ${OUT:-<vide>}"
fi

# T74 — NON-DEBORDEMENT : le meme manque sur un agent TIERS (prefixe --third-party-prefix, defaut
# gsd-) ne doit produire NI erreur NI warning citant effort. Sans cette borne, chaque SessionStart
# d'un lab equipe d'agents gsd-* cracherait un flot d'erreurs (T-24-01-01).
cat > "$AG/gsd-sans-effort.md" <<'EOF'
---
name: gsd-sans-effort
description: Agent tiers GSD depourvu d'effort, pour prouver que le durcissement ne deborde pas sur les labs.
model: sonnet
memory: project
---
corps
EOF
printf -- '---\nname: agent-conforme-t74\ndescription: Agent local conforme portant effort, pour que le run T74 ait un perimetre reel.\nmodel: sonnet\neffort: medium\nmemory: project\nskills:\n  - petit-skill\n---\ncorps\n' > "$AG/agent-conforme-t74.md"
OUT="$(run_check --strict 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "effort"; then
  ok "T74 agent tiers (prefixe gsd- par defaut) sans effort: → 0 erreur, 0 warning citant effort"
else
  ko "T74 (rc=$RC) : $OUT"
fi
rm -f "$AG/gsd-sans-effort.md" "$AG/agent-conforme-t74.md"

# T75 — DISCRIMINANCE PAR MUTATION, sur l'ARBRE REEL (pas une fixture ecrite pour l'occasion).
# Deux garde-fous avant tout verdict, au patron mutant() de test-check-gsd-config.sh:1220 :
#   - la mutation doit avoir CHANGE le fichier (comparaison par `cmp`, JAMAIS par `diff`,
#     proxifie et menteur sur ce runtime) — sinon mutant NON OPPOSABLE, pas mutant satisfait ;
#   - la reecriture LICITE (ligne restauree) doit rejouer VERT, sinon le critere serait
#     inutilisable sur du code sain.
T75_ROOT="$(cd "$SCRIPTS_DIR/../../.." && pwd)"
T75_SRC=""
for f in "$T75_ROOT"/plugin/*/agents/*.md; do
  [ -f "$f" ] || continue
  if awk 'FNR==1{fm=1;next} fm && /^---[[:space:]]*$/{fm=0} fm && /^effort:/{found=1} END{exit !found}' "$f"; then
    T75_SRC="$f"; break
  fi
done
if [ -z "$T75_SRC" ]; then
  ko "T75 (aucun agent porteur d'effort: trouve sous $T75_ROOT/plugin/*/agents — anti 'vert a vide')"
else
  MUT_AG="$WORK/mut-agents"; rm -rf "$MUT_AG"; mkdir -p "$MUT_AG"
  T75_BASE="$(basename "$T75_SRC")"
  T75_ORIG="$WORK/t75-original"          # hors de $MUT_AG : le gate ne doit voir qu'UN fichier
  cat "$T75_SRC" > "$T75_ORIG"
  # mutant : la ligne effort: du frontmatter est retiree
  awk 'FNR==1{fm=1;print;next} fm && /^---[[:space:]]*$/{fm=0;print;next} fm && /^effort:/{next} {print}' \
    "$T75_ORIG" > "$MUT_AG/$T75_BASE"
  if cmp -s "$MUT_AG/$T75_BASE" "$T75_ORIG"; then
    ko "T75 la mutation n'a RIEN change (ligne effort: introuvable dans $T75_BASE) — mutant NON OPPOSABLE, pas mutant satisfait"
  else
    OUT_MUT="$(bash "$CHECK" --agents-dir="$MUT_AG" --skills-dir="$SK" 2>&1)"; RC_MUT=$?
    # reecriture LICITE : la ligne est restauree a l'identique
    cat "$T75_ORIG" > "$MUT_AG/$T75_BASE"
    OUT_LIC="$(bash "$CHECK" --agents-dir="$MUT_AG" --skills-dir="$SK" 2>&1)"; RC_LIC=$?
    if [ "$RC_MUT" -eq 1 ] && echo "$OUT_MUT" | grep -q "effort absent" && [ "$RC_LIC" -eq 0 ]; then
      ok "T75 mutation sur l'arbre reel ($T75_BASE) : effort: retire → gate ROUGE (rc=1, message effort) ; ligne restauree → gate VERT (rc=0)"
    else
      ko "T75 (mutant rc=$RC_MUT, licite rc=$RC_LIC) mutant:[$OUT_MUT] licite:[$OUT_LIC]"
    fi
  fi
  rm -rf "$MUT_AG"; rm -f "$T75_ORIG"
fi

# ---------- T76 : la marge de profondeur de dispatch, PERIMEE par la mesure reelle (zone 6, ----
# ---------- GSDA-22, hotfix v2.63.2 2026-09-17) ------------------------------------------------
# La lecture du 2026-08-04 (descripteur maxDepth: 5, "deux niveaux de marge", un sous-worker
# licite "a n'importe quel etage") tenait sur la FOI du descripteur, jamais sur une sonde. La
# mesure du 2026-09-17 la contredit : aux profondeurs 1 et 2, Agent est visible et un lancement
# est accepte ; a la profondeur 3, Agent ET Task sont ABSENTS (ToolSearch select:Agent,Task ->
# "No matching deferred tools found."). C'est un fait de runtime commun a TOUTES les equipes du
# kernel, donc loge dans team-kernel.md (ADR-057 — une capacite, une seule voix), pas dans un
# module metier. Litteraux gardes, chacun portant un fait DISTINCT — retirer n'importe lequel
# doit rendre la doctrine incomplete :
#   PERIMEE                → la lecture du 2026-08-04 est explicitement retiree, pas taisee
#   2026-09-17              → la date de la mesure qui la perime
#   profondeur 3            → l'etage ou Agent/Task sont constates absents
#   manager 1, `vf-coder` 2, briques GSD 3 → la nouvelle distribution des profondeurs visees
#   descripteur verbatim (7 champs) → le fait de runtime brut reste recopie tel quel (non reinterprete)
T76_KERNEL="$(cd "$SCRIPTS_DIR/.." && pwd)/references/team-kernel.md"

# Detection FACTORISEE en fonction (patron T38 t38a_gate/t38d_affirmative_hits,
# test-dev-orchestrator.sh:6706 et 6778) : c'est la MEME boucle qui sert au controle primaire
# de T76 et a la preuve de discriminance par mutation plus bas — une regression de la boucle
# reelle rougit forcement le sous-test de mutation, plus de tautologie grep-contre-grep sur un
# grep -v independant qui n'exerce jamais la detection reelle (revue hotfix v2.63.2).
t76_detect() { # <file> -> imprime les litteraux/champs manquants entre crochets (vide = complet)
  local f="$1" manquants="" lit
  for lit in "PÉRIMÉE" "2026-09-17" "profondeur 3" "manager 1, \`vf-coder\` 2, briques GSD 3" \
             "2026-08-04" "1.9.1"; do
    grep -qF "$lit" "$f" || manquants="$manquants [$lit]"
  done
  # les 7 champs du descripteur, recopies verbatim (fait de runtime brut, non reinterprete)
  for lit in "namedDispatch: true" "nested: true" "maxDepth: 5" "background: true" \
             "backgroundDispatch: false" "subagentToolkit: \"full\"" "isolation: \"harness-worktree\""; do
    grep -qF "$lit" "$f" || manquants="$manquants [$lit]"
  done
  printf '%s' "$manquants"
}

if [ ! -f "$T76_KERNEL" ]; then
  ko "T76 team-kernel.md introuvable ($T76_KERNEL) — anti 'vert a vide'"
else
  T76_MANQUANTS="$(t76_detect "$T76_KERNEL")"
  if [ -z "$T76_MANQUANTS" ]; then
    ok "T76 team-kernel.md : lecture 2026-08-04 marquee PERIMEE par la mesure du 2026-09-17 (Agent/Task absents a la profondeur 3, profondeurs visees manager 1/vf-coder 2/briques GSD 3), descripteur verbatim (7 champs) toujours recopie"
  else
    ko "T76 team-kernel.md — litteraux manquants :$T76_MANQUANTS"
  fi

  # DISCRIMINANT par mutation : t76_detect() ELLE-MEME (pas un grep parallele independant) doit
  # rougir quand "profondeur 3" disparait du fichier sonde, et le motif du rouge doit etre CE
  # litteral precis (assertion sur le contenu de la liste des manquants, pas juste "non vide").
  T76_MUT="$(mktemp)"
  grep -v "profondeur 3" "$T76_KERNEL" > "$T76_MUT"
  if cmp -s "$T76_MUT" "$T76_KERNEL"; then
    ko "T76 (mutation) NON OPPOSABLE : mutant identique au fichier reel (cmp) — 'profondeur 3' introuvable sur une ligne isolee"
  else
    T76_MUT_MANQUANTS="$(t76_detect "$T76_MUT")"
    case "$T76_MUT_MANQUANTS" in
      *"[profondeur 3]"*)
        ok "T76 (mutation) (DISCRIMINANT) : t76_detect() rendue rouge sur le mutant, motif = [profondeur 3] (manquants :$T76_MUT_MANQUANTS)"
        ;;
      *)
        ko "T76 (mutation) NON DISCRIMINANTE : t76_detect() sur le mutant ne signale pas [profondeur 3] (obtenu :$T76_MUT_MANQUANTS)"
        ;;
    esac
  fi
  rm -f "$T76_MUT"
fi

# ---------- T77-T82 : Manifeste daté (Phase 42, FABR-01, D-01/D-03/D-17) ----------
# Chaque cas travaille dans son propre dossier de gate (mk_gate_dir) et son propre dossier
# d'agents, agent conforme produit par mk_conforme_agent (meme patron que good_agent, mais un
# nom parametrable pour eviter les collisions entre sous-cas).
mk_conforme_agent() { # <dossier> <nom>
  cat > "$1/$2.md" <<EOF
---
name: $2
description: Agent conforme utilise par le harnais manifeste date pour prouver un verdict.
tools: Read
disallowedTools: Write, Edit
omitClaudeMd: true
model: sonnet
memory: project
effort: low
---
corps
EOF
}

T_MANIFESTE_AG="$WORK/t-manifeste-ag"; mkdir -p "$T_MANIFESTE_AG"
mk_conforme_agent "$T_MANIFESTE_AG" "conforme"

# T77 — manifeste absent
T77_DIR="$(mk_gate_dir "$WORK/t77" 0 absent)"
OUT="$(bash "$T77_DIR/check-agents.sh" --strict --agents-dir="$T_MANIFESTE_AG" 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "MANIFESTE-ILLISIBLE"; then
  ok "T77 manifeste absent + agent conforme, --strict → rc=1, MANIFESTE-ILLISIBLE"
else
  ko "T77 (rc=$RC) : $OUT"
fi
T77_AG_VIDE="$WORK/t77-vide"; mkdir -p "$T77_AG_VIDE"
OUT="$(bash "$T77_DIR/check-agents.sh" --strict --agents-dir="$T77_AG_VIDE" 2>&1)"; RC=$?
if [ "$RC" -eq 3 ] && ! echo "$OUT" | grep -q "MANIFESTE-ILLISIBLE"; then
  ok "T77 (jumeau F13) manifeste absent + dossier d'agents vide, --strict → rc=3 (manifeste non requis)"
else
  ko "T77 (jumeau F13, rc=$RC) : $OUT"
fi

# T78 — manifeste tronque (JSON invalide)
T78_DIR="$(mk_gate_dir "$WORK/t78" 0 tronque)"
OUT="$(bash "$T78_DIR/check-agents.sh" --strict --agents-dir="$T_MANIFESTE_AG" 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "MANIFESTE-ILLISIBLE"; then
  ok "T78 manifeste tronqué (JSON invalide) + agent conforme, --strict → rc=1, MANIFESTE-ILLISIBLE"
else
  ko "T78 (rc=$RC) : $OUT"
fi

# T79 — schema invalide, un sous-cas par defaut (9 sous-cas)
T79_CASES="sans-valide-jours valide-jours=0 valide-jours=true sans-liste=outils liste-vide=outils date-invalide=outils source-invalide=outils liste-inconnue valeur-hors-charset=outils"
T79_ALL_OK=1
for t79op in $T79_CASES; do
  t79_safe="$(printf '%s' "$t79op" | tr '=:' '__')"
  T79_DIR="$(mk_gate_dir "$WORK/t79-$t79_safe" 0 "$t79op")"
  OUT="$(bash "$T79_DIR/check-agents.sh" --strict --agents-dir="$T_MANIFESTE_AG" 2>&1)"; RC=$?
  if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "MANIFESTE-ILLISIBLE"; then
    :
  else
    T79_ALL_OK=0
    ko "T79 schema invalide ($t79op) → attendu rc=1+MANIFESTE-ILLISIBLE, obtenu rc=$RC : $OUT"
  fi
done
[ "$T79_ALL_OK" -eq 1 ] && ok "T79 schema invalide — 9 sous-cas (valide_jours absent/0/booléen, liste absente, valeurs vides, verifie_le non ISO, source non https, liste inconnue, valeur hors charset) → rc=1 + MANIFESTE-ILLISIBLE"
OUT="$(bash "$GATE_DIR/check-agents.sh" --strict --agents-dir="$T_MANIFESTE_AG" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ]; then
  ok "T79 (jumeau vert) même agent, manifeste du jour complet → rc=0"
else
  ko "T79 (jumeau vert, rc=$RC) : $OUT"
fi

# T80 — source unique (D-01) : c'est le manifeste qui decide, aucune copie dans le script
T80_MISS_DIR="$(mk_gate_dir "$WORK/t80-miss-tool" 0 "retire=outils:ListAgents")"
T80_AG1="$WORK/t80-ag1"; mkdir -p "$T80_AG1"
cat > "$T80_AG1/agent-listagents.md" <<'EOF'
---
name: agent-listagents
description: Agent qui declare ListAgents dans tools, pour prouver D-01 (source unique).
tools: Read, ListAgents
disallowedTools: Write, Edit
omitClaudeMd: true
model: sonnet
memory: project
effort: low
---
corps
EOF
OUT="$(bash "$T80_MISS_DIR/check-agents.sh" --strict --agents-dir="$T80_AG1" 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "outil hors du set connu 'ListAgents'"; then
  ok "T80 manifeste PRIVÉ de ListAgents + agent le déclarant, --strict → rc=1 (outil hors du set connu)"
else
  ko "T80 (rc=$RC) : $OUT"
fi
OUT="$(bash "$GATE_DIR/check-agents.sh" --strict --agents-dir="$T80_AG1" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ]; then
  ok "T80 manifeste COMPLET (ListAgents présent) + même agent, --strict → rc=0"
else
  ko "T80 (manifeste complet, rc=$RC) : $OUT"
fi

T80_MISS2_DIR="$(mk_gate_dir "$WORK/t80-miss-field" 0 "retire=champs_frontmatter:omitClaudeMd")"
T80_AG2="$WORK/t80-ag2"; mkdir -p "$T80_AG2"
cat > "$T80_AG2/agent-omitclaudemd.md" <<'EOF'
---
name: agent-omitclaudemd
description: Agent qui declare omitClaudeMd, pour prouver D-01 (source unique, champ de frontmatter).
tools: Read
disallowedTools: Write, Edit
model: sonnet
memory: project
effort: low
omitClaudeMd: true
---
corps
EOF
OUT="$(bash "$T80_MISS2_DIR/check-agents.sh" --agents-dir="$T80_AG2" 2>&1)"; RC=$?
if echo "$OUT" | grep -qE "champ inconnu du runtime.*omitClaudeMd"; then
  ok "T80 manifeste PRIVÉ d'omitClaudeMd + agent le portant → avertissement champ inconnu présent"
else
  ko "T80 (champ manquant, rc=$RC) : $OUT"
fi
OUT="$(bash "$GATE_DIR/check-agents.sh" --agents-dir="$T80_AG2" 2>&1)"; RC=$?
if ! echo "$OUT" | grep -qE "champ inconnu du runtime.*omitClaudeMd"; then
  ok "T80 manifeste COMPLET (omitClaudeMd présent) + même agent → avertissement absent"
else
  ko "T80 (manifeste complet, champ) : $OUT"
fi

# T81 — manifeste VERSIONNE copie tel quel (dates d'origine)
T81_DIR="$(mk_gate_dir "$WORK/t81" 0 dates-reelles)"
T81_AG="$WORK/t81-ag"; mkdir -p "$T81_AG"
cat > "$T81_AG/agent-t81.md" <<'EOF'
---
name: agent-t81
description: Agent qui declare les trois outils ajoutes et experimental, pour prouver T81 (D-17).
tools: Read, ListAgents, SendFeedback, SubagentHandback
disallowedTools: Write, Edit
omitClaudeMd: true
model: sonnet
memory: project
effort: low
experimental: true
---
corps
EOF
OUT="$(bash "$T81_DIR/check-agents.sh" --strict --agents-dir="$T81_AG" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "MANIFESTE-ILLISIBLE" \
   && ! echo "$OUT" | grep -qE "champ inconnu du runtime.*experimental"; then
  ok "T81 manifeste VERSIONNÉ (dates d'origine) + agent conforme, --strict → rc=0, ListAgents/SendFeedback/SubagentHandback et experimental acceptés"
else
  ko "T81 (rc=$RC) : $OUT"
fi

# T82 — --hook (silence de code, jamais de message) + garde (fail-open documenté)
T82_DIR="$(mk_gate_dir "$WORK/t82" 0 absent)"
OUT="$(bash "$T82_DIR/check-agents.sh" --hook --agents-dir="$T_MANIFESTE_AG" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "MANIFESTE-ILLISIBLE"; then
  ok "T82 --hook, manifeste absent + agent → rc=0 ET sortie contenant MANIFESTE-ILLISIBLE (silence de code, jamais de message)"
else
  ko "T82 (--hook, rc=$RC) : '$OUT'"
fi

mkdir -p "$WORK/t82-lab/.claude/agents"
T82_GOOD="$WORK/t82-good-src.md"
mk_conforme_agent "$WORK" "t82-good-src"
OUT_GUARD="$(payload_write "$WORK/t82-lab/.claude/agents/t82-good-src.md" "$T82_GOOD" | ( cd "$WORK/t82-lab" && bash "$T82_DIR/guard-agent-write.sh" 2>/dev/null ))"
if [ -z "$OUT_GUARD" ]; then
  ok "T82 (garde) manifeste absent, agent conforme → sortie vide (fail-open documenté, laisse passer)"
else
  ko "T82 (garde) sortie non vide : $OUT_GUARD"
fi

# ---------- T83-T90 : fraîcheur du manifeste (Phase 42, FABR-02, D-02/D-04/D-05) ----------
# Age périmé = valide_jours du manifeste VERSIONNÉ + 1, lu par Python (mk_manifest), jamais un
# 31 écrit en dur — si le manifeste versionné change un jour de valide_jours, ces cas suivent.
PERIME_AGE="$("$PYBIN" -c "import json,sys; print(json.load(open(sys.argv[1]))['valide_jours'] + 1)" "$REAL_MANIFEST")"

# T83 — outil hors du set connu, périmé : warning suffixé retrograde ; frais : erreur sans suffixe
T83_PERIME_DIR="$(mk_gate_dir "$WORK/t83-perime" "$PERIME_AGE")"
T83_AG="$WORK/t83-ag"; mkdir -p "$T83_AG"
cat > "$T83_AG/agent-t83.md" <<'EOF'
---
name: agent-t83
description: Agent qui declare l'outil Reed (typo), pour prouver la retrogradation D-05.
tools: Read, Reed
disallowedTools: Write, Edit
omitClaudeMd: true
model: sonnet
memory: project
effort: low
---
corps
EOF
OUT="$(bash "$T83_PERIME_DIR/check-agents.sh" --strict --agents-dir="$T83_AG" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "outil hors du set connu 'Reed'" \
   && echo "$OUT" | grep -q "retrograde" && echo "$OUT" | grep -q "MANIFESTE-PERIME"; then
  ok "T83 manifeste périmé + tools: Read, Reed, --strict → rc=0, warning suffixé retrograde, MANIFESTE-PERIME"
else
  ko "T83 (rc=$RC) : $OUT"
fi
T83_FRAIS_DIR="$(mk_gate_dir "$WORK/t83-frais" 0)"
OUT="$(bash "$T83_FRAIS_DIR/check-agents.sh" --strict --agents-dir="$T83_AG" 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && ! echo "$OUT" | grep -q "retrograde"; then
  ok "T83 (jumeau frais) même agent, manifeste frais, --strict → rc=1 sans retrograde"
else
  ko "T83 (jumeau frais, rc=$RC) : $OUT"
fi

# T84 — INDÉTERMINÉ (D-04) sous --manifest-freshness=strict seulement ; jamais « ✓ agents conformes »
T84_PERIME_DIR="$(mk_gate_dir "$WORK/t84-perime" "$PERIME_AGE")"
OUT="$(bash "$T84_PERIME_DIR/check-agents.sh" --manifest-freshness=strict --agents-dir="$T_MANIFESTE_AG" 2>&1)"; RC=$?
if [ "$RC" -eq 3 ] && echo "$OUT" | grep -q "INDETERMINE" && echo "$OUT" | grep -q "MANIFESTE-PERIME" \
   && ! echo "$OUT" | grep -q "agents conformes"; then
  ok "T84 périmé + --manifest-freshness=strict + agent conforme → rc=3 INDETERMINE MANIFESTE-PERIME, jamais « ✓ agents conformes »"
else
  ko "T84 (rc=$RC) : $OUT"
fi
T84_FRAIS_DIR="$(mk_gate_dir "$WORK/t84-frais" 0)"
OUT="$(bash "$T84_FRAIS_DIR/check-agents.sh" --manifest-freshness=strict --agents-dir="$T_MANIFESTE_AG" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ]; then
  ok "T84 (jumeau frais) même option, manifeste frais → rc=0"
else
  ko "T84 (jumeau frais, rc=$RC) : $OUT"
fi
OUT="$(bash "$T84_PERIME_DIR/check-agents.sh" --agents-dir="$T_MANIFESTE_AG" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "MANIFESTE-PERIME" && ! echo "$OUT" | grep -q "✗"; then
  ok "T84 périmé SANS option → rc=0, MANIFESTE-PERIME présent, aucun ✗"
else
  ko "T84 (sans option, rc=$RC) : $OUT"
fi

# T85 — bornes exactes (age == valide_jours vs valide_jours + 1), y compris valide_jours custom
T85_EQ_DIR="$(mk_gate_dir "$WORK/t85-eq" 30)"
OUT="$(bash "$T85_EQ_DIR/check-agents.sh" --manifest-freshness=strict --agents-dir="$T_MANIFESTE_AG" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "MANIFESTE-PERIME"; then
  ok "T85 âge = valide_jours (30) → rc=0, aucun MANIFESTE-PERIME"
else
  ko "T85 (âge=valide_jours, rc=$RC) : $OUT"
fi
T85_PLUS1_DIR="$(mk_gate_dir "$WORK/t85-plus1" 31)"
OUT="$(bash "$T85_PLUS1_DIR/check-agents.sh" --manifest-freshness=strict --agents-dir="$T_MANIFESTE_AG" 2>&1)"; RC=$?
[ "$RC" -eq 3 ] && ok "T85 âge = valide_jours + 1 (31) → rc=3" || ko "T85 (âge=valide_jours+1, rc=$RC) : $OUT"
T85_V5_EQ_DIR="$(mk_gate_dir "$WORK/t85-v5-eq" 5 "valide-jours=5")"
OUT="$(bash "$T85_V5_EQ_DIR/check-agents.sh" --manifest-freshness=strict --agents-dir="$T_MANIFESTE_AG" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "T85 valide-jours=5, âge=5 → rc=0" || ko "T85 (valide-jours=5 âge=5, rc=$RC) : $OUT"
T85_V5_PLUS1_DIR="$(mk_gate_dir "$WORK/t85-v5-plus1" 6 "valide-jours=5")"
OUT="$(bash "$T85_V5_PLUS1_DIR/check-agents.sh" --manifest-freshness=strict --agents-dir="$T_MANIFESTE_AG" 2>&1)"; RC=$?
[ "$RC" -eq 3 ] && ok "T85 valide-jours=5, âge=6 → rc=3" || ko "T85 (valide-jours=5 âge=6, rc=$RC) : $OUT"

# T86 — date-future (T-42-13) : une seule liste forgée dans le futur, les autres du jour
T86_STRICT_DIR="$(mk_gate_dir "$WORK/t86-strict" 0 "date-future=outils")"
OUT="$(bash "$T86_STRICT_DIR/check-agents.sh" --manifest-freshness=strict --agents-dir="$T_MANIFESTE_AG" 2>&1)"; RC=$?
if [ "$RC" -eq 3 ] && echo "$OUT" | grep -q "DATE-FUTURE"; then
  ok "T86 date-future=outils (autres listes du jour) + option strict → rc=3, DATE-FUTURE"
else
  ko "T86 (strict, rc=$RC) : $OUT"
fi
T86_SANS_DIR="$(mk_gate_dir "$WORK/t86-sans" 0 "date-future=outils")"
OUT="$(bash "$T86_SANS_DIR/check-agents.sh" --agents-dir="$T_MANIFESTE_AG" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "MANIFESTE-PERIME"; then
  ok "T86 date-future=outils sans option → rc=0, MANIFESTE-PERIME"
else
  ko "T86 (sans option, rc=$RC) : $OUT"
fi

# T87 — --hook (silence total sous manifeste frais, jamais sous manifeste périmé) + cible vide
T87_PERIME_DIR="$(mk_gate_dir "$WORK/t87-perime" "$PERIME_AGE")"
T87_AG="$WORK/t87-ag"; mkdir -p "$T87_AG"
cat > "$T87_AG/agent-t87.md" <<'EOF'
---
name: agent-t87
description: Agent entierement conforme (skills declare), pour prouver le silence total sous --hook.
tools: Read
disallowedTools: Write, Edit
omitClaudeMd: true
model: sonnet
memory: project
effort: low
skills:
  - petit-skill
---
corps
EOF
OUT="$(bash "$T87_PERIME_DIR/check-agents.sh" --hook --agents-dir="$T87_AG" --skills-dir="$SK" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "MANIFESTE-PERIME"; then
  ok "T87 --hook, périmé + agent conforme (skills déclaré) → rc=0, sortie contenant MANIFESTE-PERIME"
else
  ko "T87 (hook périmé, rc=$RC) : '$OUT'"
fi
T87_FRAIS_DIR="$(mk_gate_dir "$WORK/t87-frais" 0)"
OUT="$(bash "$T87_FRAIS_DIR/check-agents.sh" --hook --agents-dir="$T87_AG" --skills-dir="$SK" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "T87 --hook, frais + même agent → sortie vide"
else
  ko "T87 (hook frais, rc=$RC) : '$OUT'"
fi
T87_VIDE_AG="$WORK/t87-vide"; mkdir -p "$T87_VIDE_AG"
OUT="$(bash "$T87_PERIME_DIR/check-agents.sh" --strict --agents-dir="$T87_VIDE_AG" 2>&1)"; RC=$?
if [ "$RC" -eq 3 ] && ! echo "$OUT" | grep -q "MANIFESTE-PERIME"; then
  ok "T87 dossier vide + --strict + périmé → rc=3 sans MANIFESTE-PERIME (fraîcheur non évaluée)"
else
  ko "T87 (dossier vide, rc=$RC) : $OUT"
fi

# T88 — Pitfall 3 : model/memory/effort invalides restent bloquants même sous manifeste périmé
T88_DIR="$(mk_gate_dir "$WORK/t88" "$PERIME_AGE")"
T88_AG="$WORK/t88-ag"; mkdir -p "$T88_AG"
cat > "$T88_AG/agent-t88.md" <<'EOF'
---
name: agent-t88
description: Agent aux enums invalides, pour prouver que model/memory/effort restent bloquants meme sous manifeste perime.
model: gpt-4
memory: global
effort: extreme
---
corps
EOF
OUT="$(bash "$T88_DIR/check-agents.sh" --agents-dir="$T88_AG" 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "model invalide" && echo "$OUT" | grep -q "memory invalide" \
   && echo "$OUT" | grep -q "effort invalide"; then
  ok "T88 (Pitfall 3) manifeste périmé + model/memory/effort invalides → rc=1, les trois restent bloquants"
else
  ko "T88 (rc=$RC) : $OUT"
fi

# T89 — --resolve-agents=strict + allowlist non résolue (registre de T30) : rétrogradée si périmé
T89_PERIME_DIR="$(mk_gate_dir "$WORK/t89-perime" "$PERIME_AGE")"
T89_AG="$WORK/t89-ag"; mkdir -p "$T89_AG"
cat > "$T89_AG/agent-t89.md" <<'EOF'
---
name: agent-t89
description: Agent qui declare une allowlist non resolue, pour prouver la retrogradation D-05 sous --resolve-agents=strict.
tools: Read, SendMessage, Agent(vf-codeur)
disallowedTools: Write, Edit
model: sonnet
memory: project
effort: low
---
corps
EOF
OUT="$(bash "$T89_PERIME_DIR/check-agents.sh" --resolve-agents=strict --agent-registry-dir="$REG" --agents-dir="$T89_AG" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "non resolu" && echo "$OUT" | grep -q "retrograde"; then
  ok "T89 périmé + --resolve-agents=strict + allowlist non résolue (registre T30) → rc=0, non resolu + retrograde"
else
  ko "T89 (rc=$RC) : $OUT"
fi
T89_FRAIS_DIR="$(mk_gate_dir "$WORK/t89-frais" 0)"
OUT="$(bash "$T89_FRAIS_DIR/check-agents.sh" --resolve-agents=strict --agent-registry-dir="$REG" --agents-dir="$T89_AG" 2>&1)"; RC=$?
[ "$RC" -eq 1 ] && ok "T89 (jumeau frais) même allowlist, manifeste frais → rc=1" || ko "T89 (jumeau frais, rc=$RC) : $OUT"

# T90 — garde d'écriture : laisse passer sous manifeste périmé, refuse sous manifeste frais ;
# --manifest-freshness=<valeur inconnue> → rc=1 explicite, jamais un repli muet
T90_PERIME_DIR="$(mk_gate_dir "$WORK/t90-perime" "$PERIME_AGE")"
T90_FRAIS_DIR="$(mk_gate_dir "$WORK/t90-frais" 0)"
T90_SRC="$WORK/t90-reed-src.md"
cat > "$T90_SRC" <<'EOF'
---
name: agent-t90
description: Agent qui declare l'outil Reed (typo), pour prouver le comportement de la garde sous manifeste perime.
tools: Read, Reed
disallowedTools: Write, Edit
omitClaudeMd: true
model: sonnet
memory: project
effort: low
---
corps
EOF
mkdir -p "$WORK/t90-lab/.claude/agents"
OUT_GUARD="$(payload_write "$WORK/t90-lab/.claude/agents/agent-t90.md" "$T90_SRC" | ( cd "$WORK/t90-lab" && bash "$T90_PERIME_DIR/guard-agent-write.sh" 2>/dev/null ))"
if [ -z "$OUT_GUARD" ]; then
  ok "T90 garde : dossier de gate périmé + tools: Read, Reed → sortie vide (laisse passer)"
else
  ko "T90 (garde périmé) sortie non vide : $OUT_GUARD"
fi
OUT_GUARD="$(payload_write "$WORK/t90-lab/.claude/agents/agent-t90.md" "$T90_SRC" | ( cd "$WORK/t90-lab" && bash "$T90_FRAIS_DIR/guard-agent-write.sh" 2>/dev/null ))"
if echo "$OUT_GUARD" | grep -q "outil hors du set connu"; then
  ok "T90 garde : dossier frais → refus JSON citant « outil hors du set connu »"
else
  ko "T90 (garde frais) sortie : $OUT_GUARD"
fi
OUT="$(bash "$T90_FRAIS_DIR/check-agents.sh" --manifest-freshness=stricte --agents-dir="$T_MANIFESTE_AG" 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q -- "--manifest-freshness invalide"; then
  ok "T90 --manifest-freshness=stricte (typo) → rc=1, « --manifest-freshness invalide »"
else
  ko "T90 (option invalide, rc=$RC) : $OUT"
fi

# ---------- MUT-F1/MUT-F2/MUT-D20 : mutation QUAL-01 (fraîcheur + D-20) ----------

# MUT-F1 — perimees = manifeste_perime( → perimees = [] (fixture T84) : rc_orig=3, rc_mut=0
MUT_F1_DIR="$(make_gate_mutant F1 "$PERIME_AGE" 'perimees = manifeste_perime(' 'perimees = []')"
MUT_F1_RC=$?
if [ "$MUT_F1_RC" -eq 0 ]; then
  MUT_F1_ORIG_DIR="$(mk_gate_dir "$WORK/mut-F1-orig" "$PERIME_AGE")"
  RC_ORIG=0; bash "$MUT_F1_ORIG_DIR/check-agents.sh" --manifest-freshness=strict --agents-dir="$T_MANIFESTE_AG" >/dev/null 2>&1 || RC_ORIG=$?
  OUT_MUT="$(bash "$MUT_F1_DIR/check-agents.sh" --manifest-freshness=strict --agents-dir="$T_MANIFESTE_AG" 2>&1)"; RC_MUT=$?
  if [ "$RC_MUT" -eq 0 ] && [ "$RC_ORIG" -eq 3 ] && ! echo "$OUT_MUT" | grep -q "Traceback"; then
    okmut F1 "$RC_MUT" 0 "$RC_ORIG" 3
  else
    komut F1 "rc_mutant=0 et rc_original=3, sans Traceback" "rc_mutant=0, rc_original=3" "rc_mutant=$RC_MUT, rc_original=$RC_ORIG :: $OUT_MUT"
  fi
fi

# MUT-F2 — retrograder = bool(perimees) → retrograder = False (fixture T83) : rc_orig=0, rc_mut=1
MUT_F2_DIR="$(make_gate_mutant F2 "$PERIME_AGE" 'retrograder = bool(perimees)' 'retrograder = False')"
MUT_F2_RC=$?
if [ "$MUT_F2_RC" -eq 0 ]; then
  MUT_F2_ORIG_DIR="$(mk_gate_dir "$WORK/mut-F2-orig" "$PERIME_AGE")"
  MUT_F2_AG="$WORK/mut-F2-ag"; mkdir -p "$MUT_F2_AG"
  cat > "$MUT_F2_AG/agent-mutf2.md" <<'EOF'
---
name: agent-mutf2
description: Agent qui declare l'outil Reed (typo), fixture de mutation MUT-F2.
tools: Read, Reed
disallowedTools: Write, Edit
omitClaudeMd: true
model: sonnet
memory: project
effort: low
---
corps
EOF
  RC_ORIG=0; bash "$MUT_F2_ORIG_DIR/check-agents.sh" --strict --agents-dir="$MUT_F2_AG" >/dev/null 2>&1 || RC_ORIG=$?
  OUT_MUT="$(bash "$MUT_F2_DIR/check-agents.sh" --strict --agents-dir="$MUT_F2_AG" 2>&1)"; RC_MUT=$?
  if [ "$RC_ORIG" -eq 0 ] && [ "$RC_MUT" -eq 1 ] && echo "$OUT_MUT" | grep -q "outil hors du set connu" \
     && ! echo "$OUT_MUT" | grep -q "Traceback"; then
    okmut F2 "$RC_MUT" 1 "$RC_ORIG" 0
  else
    komut F2 "rc_mutant=1 et rc_original=0, sortie mutant avec outil hors du set connu, sans Traceback" "rc_mutant=1, rc_original=0" "rc_mutant=$RC_MUT, rc_original=$RC_ORIG :: $OUT_MUT"
  fi
fi

# MUT-D20 (CORRECTIF DE REVUE, mission revise-42c) — cible_absente = (not single) and not
# os.path.isdir(agents_dir) → cible_absente = False (fixture T103, rejouée nue) : rc_orig=3,
# rc_mut=0. Posé ici (42-04) : les helpers de mutation n'existent qu'à partir de cette tâche —
# 42-01 (vague 1) ne pouvait pas les présupposer.
MUT_D20_DIR="$(make_gate_mutant D20 0 'cible_absente = (not single) and not os.path.isdir(agents_dir)' 'cible_absente = False')"
MUT_D20_RC=$?
if [ "$MUT_D20_RC" -eq 0 ]; then
  MUT_D20_ORIG_DIR="$(mk_gate_dir "$WORK/mut-D20-orig" 0)"
  MUT_D20_ABSENT_ORIG="$(mktemp -d)"
  RC_ORIG=0; ( cd "$MUT_D20_ABSENT_ORIG" && bash "$MUT_D20_ORIG_DIR/check-agents.sh" ) >/dev/null 2>&1 || RC_ORIG=$?
  rm -rf "$MUT_D20_ABSENT_ORIG"
  MUT_D20_ABSENT_MUT="$(mktemp -d)"
  OUT_MUT="$( cd "$MUT_D20_ABSENT_MUT" && bash "$MUT_D20_DIR/check-agents.sh" 2>&1 )"; RC_MUT=$?
  rm -rf "$MUT_D20_ABSENT_MUT"
  if [ "$RC_ORIG" -eq 3 ] && [ "$RC_MUT" -eq 0 ] && ! echo "$OUT_MUT" | grep -q "Traceback"; then
    okmut D20 "$RC_MUT" 0 "$RC_ORIG" 3
  else
    komut D20 "rc_mutant=0 et rc_original=3, sans Traceback" "rc_mutant=0, rc_original=3" "rc_mutant=$RC_MUT, rc_original=$RC_ORIG :: $OUT_MUT"
  fi
fi

# ---------- T72 : assertion sur l'arbre REEL (pas une fixture) — WINDOWS #1 ----------
# team-kernel.md affirmait l'anti-triche P12 "verifie par les suites de test de chaque module" —
# faux (aucune suite de module n'y touche, cf. team-kernel.md ligne 23 corrigee). Le seul
# mecanisme reel est check-agents.sh --strict passe par la CI sur plugin/*/agents, jamais teste
# en local sur l'arbre reel jusqu'ici (test-check-agents.sh ne teste que $AG, une fixture
# temporaire — cf. commentaire "Chemin par DEFAUT des gates" plus haut). Ce cas comble ce trou.
REPO_ROOT="$(cd "$SCRIPTS_DIR/../../.." && pwd)"
T72_CANDIDATES=""
T72_N=0
for f in "$REPO_ROOT"/plugin/*/agents/*.md; do
  [ -f "$f" ] || continue
  mem_line="$(grep -E '^memory:[[:space:]]*[a-zA-Z]' "$f" || true)"
  tools_line="$(grep -E '^tools:' "$f" || true)"
  [ -n "$mem_line" ] || continue
  [ -n "$tools_line" ] || continue
  # deja conforme si tools: contient Write et/ou Edit — regle non applicable (cf. check-agents.sh)
  if echo "$tools_line" | grep -Eq '(^tools:|,)[[:space:]]*(Write|Edit)[[:space:]]*(,|$)'; then
    continue
  fi
  T72_N=$((T72_N+1))
  T72_CANDIDATES="$T72_CANDIDATES
$f"
done

if [ "$T72_N" -eq 0 ]; then
  ko "T72 (decouverte vide sur $REPO_ROOT/plugin/*/agents — anti 'vert a vide', precedent Phase 19)"
else
  T72_BAD=""
  for f in $T72_CANDIDATES; do
    [ -n "$f" ] || continue
    dis_line="$(grep -E '^disallowedTools:' "$f" || true)"
    if ! echo "$dis_line" | grep -q "Write" || ! echo "$dis_line" | grep -q "Edit"; then
      T72_BAD="$T72_BAD $f"
    fi
  done
  if [ -z "$T72_BAD" ]; then
    ok "T72 arbre reel : $T72_N agent(s) memory:+tools: sans Write/Edit, tous barres par disallowedTools: Write, Edit"
  else
    ko "T72 arbre reel : disallowedTools: Write, Edit manquant sur :$T72_BAD"
  fi
fi

# ---------- T91/T91b : invariant I1 (D-06, D-18) — Phase 42, FABR-03, 42-05 Tache 1 ----------
cat > "$AG/i1-les-deux.md" <<'EOF'
---
name: i1-les-deux
description: Agent de test. Worker interne de la boucle, dispatche uniquement par un manager.
model: sonnet
effort: low
memory: project
vf-internal: true
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "invariant I1"; then
  ok "T91 vf-internal: true + marqueur present -> rc=0, aucun invariant I1"
else
  ko "T91 (les deux presents, rc=$RC) : $OUT"
fi
rm -f "$AG/i1-les-deux.md"

cat > "$AG/i1-aucun.md" <<'EOF'
---
name: i1-aucun
description: Agent de test tout ce qu il y a de plus normal, sans aucun marqueur particulier.
model: sonnet
effort: low
memory: project
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "invariant I1"; then
  ok "T91 aucun des deux (ni vf-internal, ni marqueur) -> rc=0, aucun invariant I1"
else
  ko "T91 (aucun, rc=$RC) : $OUT"
fi
rm -f "$AG/i1-aucun.md"

cat > "$AG/i1-internal-sans-marqueur.md" <<'EOF'
---
name: i1-internal-sans-marqueur
description: Agent de test interne mais dont la description ne porte pas le marqueur attendu.
model: sonnet
effort: low
memory: project
vf-internal: true
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "invariant I1"; then
  ok "T91 vf-internal: true sans marqueur -> rc=1, invariant I1"
else
  ko "T91 (internal sans marqueur, rc=$RC) : $OUT"
fi
rm -f "$AG/i1-internal-sans-marqueur.md"

cat > "$AG/i1-marqueur-sans-internal.md" <<'EOF'
---
name: i1-marqueur-sans-internal
description: Agent de test. Worker interne de la boucle, dispatche uniquement par un manager.
model: sonnet
effort: low
memory: project
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "invariant I1"; then
  ok "T91 marqueur sans vf-internal: true -> rc=1, invariant I1"
else
  ko "T91 (marqueur sans internal, rc=$RC) : $OUT"
fi
rm -f "$AG/i1-marqueur-sans-internal.md"

# T91 — mutation reelle sur le porteur reel de I1 (vf-test-runner.md) : le marqueur perd
# « interne » apres « Worker » -> rouge (invariant I1) ; copie restauree -> verte.
T91_CARRIER="$REPO_ROOT/plugin/mobile-test-team/agents/vf-test-runner.md"
if [ -f "$T91_CARRIER" ]; then
  T91_ORIG_DIR="$WORK/t91-original"; T91_MUT_DIR="$WORK/t91-mutant"
  mkdir -p "$T91_ORIG_DIR" "$T91_MUT_DIR"
  T91_BASE="$(basename "$T91_CARRIER")"
  cp "$T91_CARRIER" "$T91_ORIG_DIR/$T91_BASE"
  sed 's/Worker interne/Worker/' "$T91_CARRIER" > "$T91_MUT_DIR/$T91_BASE"
  juger_mutation_reelle "T91" "$T91_ORIG_DIR/$T91_BASE" "$T91_MUT_DIR/$T91_BASE" "invariant I1"
else
  ko "T91 mutation reelle : porteur introuvable ($T91_CARRIER)"
fi

# T91b (D-18) — forme a DEUX dispatcheurs nommes, description REELLE de vf-test-orchestrator
# (posee en 42-02) : tolerance du gate a cette formulation, jamais un decompte de dispatcheurs.
cat > "$AG/i1-deux-dispatcheurs.md" <<'EOF'
---
name: i1-deux-dispatcheurs
description: "Orchestrateur de test. Worker interne — dispatché par vf-dev-manager ou par le mode autonome (vf-auto) sur ce type de projet, pas en usage direct."
model: sonnet
effort: high
memory: project
vf-internal: true
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "invariant I1"; then
  ok "T91b forme a deux dispatcheurs nommes (D-18) + vf-internal: true -> rc=0, aucun invariant I1"
else
  ko "T91b (rc=$RC) : $OUT"
fi
rm -f "$AG/i1-deux-dispatcheurs.md"

cat > "$AG/i1-deux-dispatcheurs-negatif.md" <<'EOF'
---
name: i1-deux-dispatcheurs-negatif
description: "Orchestrateur de test. Worker interne — dispatché par vf-dev-manager ou par le mode autonome (vf-auto) sur ce type de projet, pas en usage direct."
model: sonnet
effort: high
memory: project
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "invariant I1"; then
  ok "T91b jumeau negatif (meme description, sans vf-internal: true) -> rc=1, invariant I1"
else
  ko "T91b-negatif (rc=$RC) : $OUT"
fi
rm -f "$AG/i1-deux-dispatcheurs-negatif.md"

# ---------- T92 : invariant I4 — disallowedTools sans specifieur (Phase 42, FABR-03) ----------
cat > "$AG/i4-specifier.md" <<'EOF'
---
name: i4-specifier
description: Agent de test qui restreint disallowedTools avec un specifieur au lieu de le retirer.
model: sonnet
effort: low
memory: project
tools: Read, Write, Edit, Bash
disallowedTools: Bash(rm:*)
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "invariant I4"; then
  ok "T92 disallowedTools: Bash(rm:*) (specifieur) -> rc=1, invariant I4"
else
  ko "T92 (rc=$RC) : $OUT"
fi
rm -f "$AG/i4-specifier.md"

cat > "$AG/i4-clean.md" <<'EOF'
---
name: i4-clean
description: Agent de test dont disallowedTools retire l outil entier, sans specifieur.
model: sonnet
effort: low
memory: project
tools: Read, Write, Edit, Bash
disallowedTools: Bash
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "invariant I4"; then
  ok "T92 disallowedTools: Bash (sans specifieur) -> rc=0, aucun invariant I4"
else
  ko "T92-jumeau (rc=$RC) : $OUT"
fi
rm -f "$AG/i4-clean.md"

# ---------- T95 : invariant I7 — vf-mcp-* exige vf-requires: mcp-servers (Phase 42, FABR-03) ----
cat > "$AG/i7-sans-requires.md" <<'EOF'
---
name: i7-sans-requires
description: Agent de test qui declare vf-mcp-consumer sans vf-requires correspondant.
model: sonnet
effort: low
memory: project
vf-mcp-consumer: true
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "invariant I7"; then
  ok "T95 vf-mcp-consumer: true sans vf-requires -> rc=1, invariant I7"
else
  ko "T95 (rc=$RC) : $OUT"
fi
rm -f "$AG/i7-sans-requires.md"

cat > "$AG/i7-requires-autre.md" <<'EOF'
---
name: i7-requires-autre
description: Agent de test qui declare vf-mcp-consumer avec vf-requires ne citant pas mcp-servers.
model: sonnet
effort: low
memory: project
vf-mcp-consumer: true
vf-requires: autre-chose
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "invariant I7"; then
  ok "T95 vf-requires: autre-chose (sans mcp-servers) -> rc=1, invariant I7"
else
  ko "T95-autre (rc=$RC) : $OUT"
fi
rm -f "$AG/i7-requires-autre.md"

cat > "$AG/i7-ok.md" <<'EOF'
---
name: i7-ok
description: Agent de test qui declare vf-mcp-tools avec vf-requires citant mcp-servers.
model: sonnet
effort: low
memory: project
vf-mcp-tools: XcodeBuildMCP:build_sim
vf-requires: mcp-servers
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "invariant I7"; then
  ok "T95 vf-mcp-tools + vf-requires: mcp-servers -> rc=0, aucun invariant I7"
else
  ko "T95-ok (rc=$RC) : $OUT"
fi
rm -f "$AG/i7-ok.md"

# T95 — mutation reelle sur le porteur reel de I7 (vf-test-runner.md) : la ligne vf-requires
# disparait -> rouge (invariant I7) ; copie restauree -> verte.
if [ -f "$T91_CARRIER" ]; then
  T95_ORIG_DIR="$WORK/t95-original"; T95_MUT_DIR="$WORK/t95-mutant"
  mkdir -p "$T95_ORIG_DIR" "$T95_MUT_DIR"
  T95_BASE="$(basename "$T91_CARRIER")"
  cp "$T91_CARRIER" "$T95_ORIG_DIR/$T95_BASE"
  grep -v '^vf-requires:' "$T91_CARRIER" > "$T95_MUT_DIR/$T95_BASE"
  juger_mutation_reelle "T95" "$T95_ORIG_DIR/$T95_BASE" "$T95_MUT_DIR/$T95_BASE" "invariant I7"
else
  ko "T95 mutation reelle : porteur introuvable ($T91_CARRIER)"
fi

# ---------- MUT-I1 / MUT-I4 / MUT-I7 : mutants QUAL-01 sur les lignes d'appel (Tache 1, 42-05) --
MUT_I1_DIR="$(make_gate_mutant I1 0 'errors.extend(invariant_i1(' 'pass')"
MUT_I1_RC=$?
if [ "$MUT_I1_RC" -eq 0 ]; then
  MUT_I1_ORIG_DIR="$(mk_gate_dir "$WORK/mut-I1-orig" 0)"
  MUT_I1_AG="$WORK/mut-I1-ag"; mkdir -p "$MUT_I1_AG"
  cat > "$MUT_I1_AG/agent-muti1.md" <<'EOF'
---
name: agent-muti1
description: Agent de test interne mais sans le marqueur attendu, fixture de mutation MUT-I1.
model: sonnet
effort: low
memory: project
vf-internal: true
---
corps
EOF
  RC_ORIG=0; bash "$MUT_I1_ORIG_DIR/check-agents.sh" --agents-dir="$MUT_I1_AG" >/dev/null 2>&1 || RC_ORIG=$?
  OUT_MUT="$(bash "$MUT_I1_DIR/check-agents.sh" --agents-dir="$MUT_I1_AG" 2>&1)"; RC_MUT=$?
  if [ "$RC_ORIG" -eq 1 ] && [ "$RC_MUT" -eq 0 ] && ! echo "$OUT_MUT" | grep -q "Traceback"; then
    okmut I1 "$RC_MUT" 0 "$RC_ORIG" 1
  else
    komut I1 "rc_mutant=0 et rc_original=1, sans Traceback" "rc_mutant=0, rc_original=1" "rc_mutant=$RC_MUT, rc_original=$RC_ORIG :: $OUT_MUT"
  fi
fi

MUT_I4_DIR="$(make_gate_mutant I4 0 'errors.extend(invariant_i4(' 'pass')"
MUT_I4_RC=$?
if [ "$MUT_I4_RC" -eq 0 ]; then
  MUT_I4_ORIG_DIR="$(mk_gate_dir "$WORK/mut-I4-orig" 0)"
  MUT_I4_AG="$WORK/mut-I4-ag"; mkdir -p "$MUT_I4_AG"
  cat > "$MUT_I4_AG/agent-muti4.md" <<'EOF'
---
name: agent-muti4
description: Agent de test dont disallowedTools porte un specifieur, fixture de mutation MUT-I4.
model: sonnet
effort: low
memory: project
tools: Read, Write, Edit, Bash
disallowedTools: Bash(rm:*)
---
corps
EOF
  RC_ORIG=0; bash "$MUT_I4_ORIG_DIR/check-agents.sh" --agents-dir="$MUT_I4_AG" >/dev/null 2>&1 || RC_ORIG=$?
  OUT_MUT="$(bash "$MUT_I4_DIR/check-agents.sh" --agents-dir="$MUT_I4_AG" 2>&1)"; RC_MUT=$?
  if [ "$RC_ORIG" -eq 1 ] && [ "$RC_MUT" -eq 0 ] && ! echo "$OUT_MUT" | grep -q "Traceback"; then
    okmut I4 "$RC_MUT" 0 "$RC_ORIG" 1
  else
    komut I4 "rc_mutant=0 et rc_original=1, sans Traceback" "rc_mutant=0, rc_original=1" "rc_mutant=$RC_MUT, rc_original=$RC_ORIG :: $OUT_MUT"
  fi
fi

MUT_I7_DIR="$(make_gate_mutant I7 0 'errors.extend(invariant_i7(' 'pass')"
MUT_I7_RC=$?
if [ "$MUT_I7_RC" -eq 0 ]; then
  MUT_I7_ORIG_DIR="$(mk_gate_dir "$WORK/mut-I7-orig" 0)"
  MUT_I7_AG="$WORK/mut-I7-ag"; mkdir -p "$MUT_I7_AG"
  cat > "$MUT_I7_AG/agent-muti7.md" <<'EOF'
---
name: agent-muti7
description: Agent de test qui declare vf-mcp-consumer sans vf-requires, fixture de mutation MUT-I7.
model: sonnet
effort: low
memory: project
vf-mcp-consumer: true
---
corps
EOF
  RC_ORIG=0; bash "$MUT_I7_ORIG_DIR/check-agents.sh" --agents-dir="$MUT_I7_AG" >/dev/null 2>&1 || RC_ORIG=$?
  OUT_MUT="$(bash "$MUT_I7_DIR/check-agents.sh" --agents-dir="$MUT_I7_AG" 2>&1)"; RC_MUT=$?
  if [ "$RC_ORIG" -eq 1 ] && [ "$RC_MUT" -eq 0 ] && ! echo "$OUT_MUT" | grep -q "Traceback"; then
    okmut I7 "$RC_MUT" 0 "$RC_ORIG" 1
  else
    komut I7 "rc_mutant=0 et rc_original=1, sans Traceback" "rc_mutant=0, rc_original=1" "rc_mutant=$RC_MUT, rc_original=$RC_ORIG :: $OUT_MUT"
  fi
fi

# ---------- T94 : invariant I6 — manager (allowlist Agent(...) non vide, non vf-internal) sans
# SendMessage (D-07, TOUJOURS arme, Phase 42, FABR-03, 42-05 Tache 3) ----------
cat > "$AG/i6-sans-sendmessage.md" <<'EOF'
---
name: i6-sans-sendmessage
description: Agent de test manager (allowlist non vide) sans SendMessage dans tools.
model: sonnet
effort: high
memory: project
tools: Read, Write, Agent(worker-a, worker-b)
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "invariant I6"; then
  ok "T94 manager sans SendMessage -> rc=1, invariant I6"
else
  ko "T94 (rc=$RC) : $OUT"
fi
rm -f "$AG/i6-sans-sendmessage.md"

cat > "$AG/i6-avec-sendmessage.md" <<'EOF'
---
name: i6-avec-sendmessage
description: Agent de test manager (allowlist non vide) avec SendMessage dans tools.
model: sonnet
effort: high
memory: project
tools: Read, Write, SendMessage, Agent(worker-a, worker-b)
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "invariant I6"; then
  ok "T94 manager avec SendMessage -> rc=0, aucun invariant I6"
else
  ko "T94-avec (rc=$RC) : $OUT"
fi
rm -f "$AG/i6-avec-sendmessage.md"

cat > "$AG/i6-interne.md" <<'EOF'
---
name: i6-interne
description: Agent de test. Worker interne, dispatche uniquement par un manager du team-kernel.
model: sonnet
effort: high
memory: project
tools: Read, Write, Agent(worker-a, worker-b)
vf-internal: true
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "invariant I6"; then
  ok "T94 allowlist + vf-internal: true + marqueur -> rc=0, aucun invariant I6"
else
  ko "T94-interne (rc=$RC) : $OUT"
fi
rm -f "$AG/i6-interne.md"

cat > "$AG/i6-agent-nu.md" <<'EOF'
---
name: i6-agent-nu
description: Agent de test declarant Agent sans aucune allowlist parenthesee (dispatch nu).
model: sonnet
effort: high
memory: project
tools: Read, Agent
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "invariant I6"; then
  ok "T94 Agent nu (sans allowlist) -> rc=0, aucun invariant I6"
else
  ko "T94-nu (rc=$RC) : $OUT"
fi
rm -f "$AG/i6-agent-nu.md"

# T94 — mutation reelle sur le porteur reel de I6 (vf-business-manager.md) : le jeton
# SendMessage disparait -> rouge (invariant I6) ; copie restauree -> verte.
T94_CARRIER="$REPO_ROOT/plugin/business-pilot-bundle/agents/vf-business-manager.md"
if [ -f "$T94_CARRIER" ]; then
  T94_ORIG_DIR="$WORK/t94-original"; T94_MUT_DIR="$WORK/t94-mutant"
  mkdir -p "$T94_ORIG_DIR" "$T94_MUT_DIR"
  T94_BASE="$(basename "$T94_CARRIER")"
  cp "$T94_CARRIER" "$T94_ORIG_DIR/$T94_BASE"
  sed 's/SendMessage, //' "$T94_CARRIER" > "$T94_MUT_DIR/$T94_BASE"
  juger_mutation_reelle "T94" "$T94_ORIG_DIR/$T94_BASE" "$T94_MUT_DIR/$T94_BASE" "invariant I6"
else
  ko "T94 mutation reelle : porteur introuvable ($T94_CARRIER)"
fi

# ---------- MUT-I6 : mutant QUAL-01 sur la ligne d'appel invariant_i6 (TOUJOURS) ----------
MUT_I6_DIR="$(make_gate_mutant I6 0 'errors.extend(invariant_i6(' 'pass')"
MUT_I6_RC=$?
if [ "$MUT_I6_RC" -eq 0 ]; then
  MUT_I6_ORIG_DIR="$(mk_gate_dir "$WORK/mut-I6-orig" 0)"
  MUT_I6_AG="$WORK/mut-I6-ag"; mkdir -p "$MUT_I6_AG"
  cat > "$MUT_I6_AG/agent-muti6.md" <<'EOF'
---
name: agent-muti6
description: Agent de test manager sans SendMessage, fixture de mutation MUT-I6.
model: sonnet
effort: high
memory: project
tools: Read, Write, Agent(worker-a, worker-b)
---
corps
EOF
  RC_ORIG=0; bash "$MUT_I6_ORIG_DIR/check-agents.sh" --agents-dir="$MUT_I6_AG" >/dev/null 2>&1 || RC_ORIG=$?
  OUT_MUT="$(bash "$MUT_I6_DIR/check-agents.sh" --agents-dir="$MUT_I6_AG" 2>&1)"; RC_MUT=$?
  if [ "$RC_ORIG" -eq 1 ] && [ "$RC_MUT" -eq 0 ] && ! echo "$OUT_MUT" | grep -q "Traceback"; then
    okmut I6 "$RC_MUT" 0 "$RC_ORIG" 1
  else
    komut I6 "rc_mutant=0 et rc_original=1, sans Traceback" "rc_mutant=0, rc_original=1" "rc_mutant=$RC_MUT, rc_original=$RC_ORIG :: $OUT_MUT"
  fi
fi

# ---------- Precondition de la Tache 3 : rejeu de la sonde ARBITRAGE-* (D-19/D-08) ----------
# Jamais relue en prose seule — decide si T93/MUT-I5 s'executent (branche MAINTENIR uniquement).
D19_MESURE_PATH="$REPO_ROOT/.planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-D19-MESURE.md"
ARBITRAGE_VERDICT="$("$PYBIN" -c "
import re, sys, unicodedata
p = sys.argv[1]
try:
    s = unicodedata.normalize('NFC', open(p, encoding='utf-8').read())
except FileNotFoundError:
    print('ARBITRAGE-ABSENT'); sys.exit(1)
sec = re.search(r'^##\s+Arbitrage D-08\b(.*?)(?=\n##\s|\Z)', s, re.S | re.M)
if not sec:
    print('ARBITRAGE-ABSENT'); sys.exit(1)
m = re.search(r'\*\*D.cision\s*:\*\*\s*(maintenir|renoncer)\b.*?\*\*Canal\s*:\*\*\s*(\S.*?)\s*\n.*?\*\*Date\s*:\*\*\s*(\d{4}-\d{2}-\d{2})', sec.group(1), re.S)
if not m:
    print('ARBITRAGE-ABSENT'); sys.exit(1)
print('ARBITRAGE-' + m.group(1).upper()); sys.exit(0)
" "$D19_MESURE_PATH")"
ARBITRAGE_RC=$?

if [ "$ARBITRAGE_VERDICT" = "ARBITRAGE-MAINTENIR" ]; then
  # ---------- T93 : invariant I5 — juge (disallowedTools retire Write/Edit, aucune allowlist)
  # sans omitClaudeMd: true (D-08, SEULEMENT SI ARBITRAGE-MAINTENIR) ----------
  cat > "$AG/i5-sans-omit.md" <<'EOF'
---
name: i5-sans-omit
description: Agent de test juge (disallowedTools retire Write/Edit) sans omitClaudeMd.
model: sonnet
effort: high
memory: project
tools: Read, Glob, Grep
disallowedTools: Write, Edit
---
corps
EOF
  OUT="$(run_check 2>&1)"; RC=$?
  if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "invariant I5"; then
    ok "T93 juge sans omitClaudeMd -> rc=1, invariant I5"
  else
    ko "T93 (rc=$RC) : $OUT"
  fi
  rm -f "$AG/i5-sans-omit.md"

  cat > "$AG/i5-avec-omit.md" <<'EOF'
---
name: i5-avec-omit
description: Agent de test juge (disallowedTools retire Write/Edit) avec omitClaudeMd: true.
model: sonnet
effort: high
memory: project
tools: Read, Glob, Grep
disallowedTools: Write, Edit
omitClaudeMd: true
---
corps
EOF
  OUT="$(run_check 2>&1)"; RC=$?
  if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "invariant I5"; then
    ok "T93 juge avec omitClaudeMd: true -> rc=0, aucun invariant I5"
  else
    ko "T93-avec (rc=$RC) : $OUT"
  fi
  rm -f "$AG/i5-avec-omit.md"

  cat > "$AG/i5-forme-reviewer.md" <<'EOF'
---
name: i5-forme-reviewer
description: Agent de test. Worker interne, forme vf-reviewer (allowlist Agent non vide + disallowedTools Write, Edit).
model: sonnet
effort: high
memory: project
tools: Read, Bash, Glob, Grep, Agent(outil-tiers)
disallowedTools: Write, Edit
vf-internal: true
---
corps
EOF
  OUT="$(run_check 2>&1)"; RC=$?
  if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "invariant I5"; then
    ok "T93 forme vf-reviewer (allowlist non vide) -> rc=0, aucun invariant I5 (hors classe juge)"
  else
    ko "T93-reviewer (rc=$RC) : $OUT"
  fi
  rm -f "$AG/i5-forme-reviewer.md"

  # T93 — mutation reelle sur le porteur reel de I5 (content-clarity-judge.md, deja porteur
  # d'omitClaudeMd: true depuis cette meme tache 42-05) : la ligne omitClaudeMd disparait
  # -> rouge (invariant I5) ; copie restauree -> verte.
  T93_CARRIER="$REPO_ROOT/plugin/content-bundle/agents/content-clarity-judge.md"
  if [ -f "$T93_CARRIER" ] && grep -q '^omitClaudeMd: true' "$T93_CARRIER"; then
    T93_ORIG_DIR="$WORK/t93-original"; T93_MUT_DIR="$WORK/t93-mutant"
    mkdir -p "$T93_ORIG_DIR" "$T93_MUT_DIR"
    T93_BASE="$(basename "$T93_CARRIER")"
    cp "$T93_CARRIER" "$T93_ORIG_DIR/$T93_BASE"
    grep -v '^omitClaudeMd: true' "$T93_CARRIER" > "$T93_MUT_DIR/$T93_BASE"
    juger_mutation_reelle "T93" "$T93_ORIG_DIR/$T93_BASE" "$T93_MUT_DIR/$T93_BASE" "invariant I5"
  else
    ko "T93 mutation reelle : porteur introuvable ou sans omitClaudeMd ($T93_CARRIER)"
  fi

  # ---------- MUT-I5 : mutant QUAL-01 sur la ligne d'appel invariant_i5 (SEULEMENT SI MAINTENIR) ----------
  MUT_I5_DIR="$(make_gate_mutant I5 0 'errors.extend(invariant_i5(' 'pass')"
  MUT_I5_RC=$?
  if [ "$MUT_I5_RC" -eq 0 ]; then
    MUT_I5_ORIG_DIR="$(mk_gate_dir "$WORK/mut-I5-orig" 0)"
    MUT_I5_AG="$WORK/mut-I5-ag"; mkdir -p "$MUT_I5_AG"
    cat > "$MUT_I5_AG/agent-muti5.md" <<'EOF'
---
name: agent-muti5
description: Agent de test juge sans omitClaudeMd, fixture de mutation MUT-I5.
model: sonnet
effort: high
memory: project
tools: Read, Glob, Grep
disallowedTools: Write, Edit
---
corps
EOF
    RC_ORIG=0; bash "$MUT_I5_ORIG_DIR/check-agents.sh" --agents-dir="$MUT_I5_AG" >/dev/null 2>&1 || RC_ORIG=$?
    OUT_MUT="$(bash "$MUT_I5_DIR/check-agents.sh" --agents-dir="$MUT_I5_AG" 2>&1)"; RC_MUT=$?
    if [ "$RC_ORIG" -eq 1 ] && [ "$RC_MUT" -eq 0 ] && ! echo "$OUT_MUT" | grep -q "Traceback"; then
      okmut I5 "$RC_MUT" 0 "$RC_ORIG" 1
    else
      komut I5 "rc_mutant=0 et rc_original=1, sans Traceback" "rc_mutant=0, rc_original=1" "rc_mutant=$RC_MUT, rc_original=$RC_ORIG :: $OUT_MUT"
    fi
  fi
else
  echo "  (info) T93/MUT-I5 non executes : sonde ARBITRAGE-* = $ARBITRAGE_VERDICT (rc=$ARBITRAGE_RC), attendu ARBITRAGE-MAINTENIR"
fi

# ---------- T96 : corpus reel + check-blueprints.sh (TOUJOURS, adapte a la branche) ----------
T96_FAIL=0
T96_DIRS_FOUND=0
for d in "$REPO_ROOT"/plugin/*/agents; do
  [ -d "$d" ] || continue
  T96_DIRS_FOUND=$((T96_DIRS_FOUND+1))
  OUT_T96="$(bash "$REAL_CHECK" --strict --skills-dir="$WORK/no-such-skills-dir" --agents-dir="$d" 2>&1)"; RC_T96=$?
  if [ "$RC_T96" -ne 0 ] || echo "$OUT_T96" | grep -q "invariant I6"; then
    T96_FAIL=1
    ko "T96 corpus reel ($d) : invariant I6 ou rc!=0 -> $OUT_T96"
  fi
  if [ "$ARBITRAGE_VERDICT" = "ARBITRAGE-MAINTENIR" ] && echo "$OUT_T96" | grep -q "invariant I5"; then
    T96_FAIL=1
    ko "T96 corpus reel ($d) : invariant I5 inattendu -> $OUT_T96"
  fi
done
if [ "$T96_DIRS_FOUND" -lt 6 ]; then
  T96_FAIL=1
  ko "T96 anti-vert-a-vide : seulement $T96_DIRS_FOUND dossier(s) plugin/*/agents decouvert(s), attendu >= 6"
fi
for f in "$REPO_ROOT"/plugin/*/AGENT.md; do
  [ -f "$f" ] || continue
  RC_T96F=0; bash "$REAL_CHECK" --strict --file "$f" >/dev/null 2>&1 || RC_T96F=$?
  if [ "$RC_T96F" -ne 0 ]; then
    T96_FAIL=1
    ko "T96 AGENT.md ($f) : rc=$RC_T96F attendu 0"
  fi
done
RC_T96BP=0; bash "$REPO_ROOT/plugin/conductor/scripts/check-blueprints.sh" >/dev/null 2>&1 || RC_T96BP=$?
if [ "$RC_T96BP" -ne 0 ]; then
  T96_FAIL=1
  ko "T96 check-blueprints.sh : rc=$RC_T96BP attendu 0"
fi
[ "$T96_FAIL" -eq 0 ] && ok "T96 corpus reel (>= $T96_DIRS_FOUND dossiers) + AGENT.md + check-blueprints.sh -> aucun invariant I6 (I5 si arme), rc=0"

# ---------- T97/T98/T99, MUT-D1, MUT-D2 : decouverte recursive avec exclusions prouvees ----------
# (Phase 42, FABR-04, D-10, 42-06 Tache 1) ---------------------------------------------------------
rm -rf "${AG:?}"/*

# T97 — recursion : sous-dossier equipe/sous-agent.md sans model -> rc=1, cite sous-agent.md et
# "model absent" ; rendu conforme -> rc=0.
mkdir -p "$AG/equipe"
cat > "$AG/equipe/sous-agent.md" <<'EOF'
---
name: sous-agent
description: Agent de test place dans un sous-dossier, sans model, pour prouver la recursion.
effort: low
memory: project
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "sous-agent.md" && echo "$OUT" | grep -q "model absent"; then
  ok "T97 decouverte recursive : equipe/sous-agent.md sans model -> rc=1, cite sous-agent.md et model absent"
else
  ko "T97 (rc=$RC) : $OUT"
fi
cat > "$AG/equipe/sous-agent.md" <<'EOF'
---
name: sous-agent
description: Agent de test place dans un sous-dossier, rendu conforme, pour prouver la recursion.
model: sonnet
effort: low
memory: project
---
corps
EOF
RC=0; run_check >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 0 ] && ok "T97 sous-agent rendu conforme -> rc=0" || ko "T97-conforme (rc=$RC)"
rm -rf "$AG/equipe"

# T98 — exclusions : agent conforme a la racine + lab-references/lead-knowledge.md (sans
# frontmatter) + equipe/README.md + .cache/x.md -> rc=0, aucun des trois cite.
good_agent "racine-t98"
mkdir -p "$AG/lab-references" "$AG/equipe" "$AG/.cache"
printf 'contenu de reference, pas un agent\n' > "$AG/lab-references/lead-knowledge.md"
printf 'pas un agent\n' > "$AG/equipe/README.md"
printf 'cache, jamais parcouru\n' > "$AG/.cache/x.md"
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "lead-knowledge.md" && ! echo "$OUT" | grep -q "README.md" && ! echo "$OUT" | grep -q "x.md"; then
  ok "T98 exclusions : -references/, README.md en profondeur, dossier cache -> rc=0, aucun cite"
else
  ko "T98 (rc=$RC) : $OUT"
fi
rm -rf "$AG/lab-references" "$AG/equipe" "$AG/.cache"
rm -f "$AG/racine-t98.md"

# T99 — resolution : sous-agent interne dispatche depuis equipe/ -> rc=0 sous
# --resolve-agents=strict, aucun "non resolu" (MEME decouverte pour la cible et la resolution).
mkdir -p "$AG/equipe"
cat > "$AG/equipe/sous-agent.md" <<'EOF'
---
name: sous-agent
description: Agent de test. Worker interne, dispatche par un agent racine (T99, recursion).
model: sonnet
effort: low
memory: project
vf-internal: true
---
corps
EOF
cat > "$AG/racine-t99.md" <<'EOF'
---
name: racine-t99
description: Agent de test racine qui dispatche un sous-agent via la meme decouverte recursive.
model: sonnet
effort: high
memory: project
tools: Read, SendMessage, Agent(sous-agent)
disallowedTools: Write, Edit
---
corps
EOF
OUT="$(run_check --resolve-agents=strict 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -qi "non resolu"; then
  ok "T99 resolution via la meme decouverte : sous-agent dispatche depuis equipe/ -> rc=0 sous --resolve-agents=strict, aucun 'non resolu'"
else
  ko "T99 (rc=$RC) : $OUT"
fi
rm -rf "$AG/equipe"
rm -f "$AG/racine-t99.md"

# ---------- MUT-D1 : elagage des dossiers caches remplace par un elagage total (plus aucune ----------
# ---------- descente) — fixture T97 : rc_original=1, rc_mutant=0 -------------------------------
MUT_D1_AG="$WORK/mut-D1-ag"; mkdir -p "$MUT_D1_AG/equipe"
cat > "$MUT_D1_AG/racine-mutd1.md" <<'EOF'
---
name: racine-mutd1
description: Agent de test racine conforme, fixture de mutation MUT-D1.
model: sonnet
effort: low
memory: project
skills:
  - petit-skill
---
corps
EOF
cat > "$MUT_D1_AG/equipe/sous-agent-mutd1.md" <<'EOF'
---
name: sous-agent-mutd1
description: Agent de test en sous-dossier, sans model, fixture de mutation MUT-D1.
effort: low
memory: project
---
corps
EOF
MUT_D1_DIR="$(make_gate_mutant D1 0 "dirnames[:] = [d for d in dirnames if not d.startswith('.')]" 'dirnames[:] = []')"
MUT_D1_RC=$?
if [ "$MUT_D1_RC" -eq 0 ]; then
  MUT_D1_ORIG_DIR="$(mk_gate_dir "$WORK/mut-D1-orig" 0)"
  RC_ORIG=0; bash "$MUT_D1_ORIG_DIR/check-agents.sh" --agents-dir="$MUT_D1_AG" --skills-dir="$SK" >/dev/null 2>&1 || RC_ORIG=$?
  OUT_MUT="$(bash "$MUT_D1_DIR/check-agents.sh" --agents-dir="$MUT_D1_AG" --skills-dir="$SK" 2>&1)"; RC_MUT=$?
  if [ "$RC_ORIG" -eq 1 ] && [ "$RC_MUT" -eq 0 ] && ! echo "$OUT_MUT" | grep -q "Traceback"; then
    okmut D1 "$RC_MUT" 0 "$RC_ORIG" 1
  else
    komut D1 "rc_mutant=0 et rc_original=1, sans Traceback" "rc_mutant=0, rc_original=1" "rc_mutant=$RC_MUT, rc_original=$RC_ORIG :: $OUT_MUT"
  fi
fi

# ---------- MUT-D2 : elagage des dossiers -references neutralise — fixture T98 : ----------
# ---------- rc_original=0, rc_mutant=1 ----------------------------------------------------------
MUT_D2_AG="$WORK/mut-D2-ag"; mkdir -p "$MUT_D2_AG/lab-references"
cat > "$MUT_D2_AG/racine-mutd2.md" <<'EOF'
---
name: racine-mutd2
description: Agent de test racine conforme, fixture de mutation MUT-D2.
model: sonnet
effort: low
memory: project
skills:
  - petit-skill
---
corps
EOF
printf 'contenu de reference, pas un agent, fixture MUT-D2\n' > "$MUT_D2_AG/lab-references/lead-knowledge-mutd2.md"
MUT_D2_DIR="$(make_gate_mutant D2 0 "dirnames[:] = [d for d in dirnames if not d.endswith('-references')]" 'pass')"
MUT_D2_RC=$?
if [ "$MUT_D2_RC" -eq 0 ]; then
  MUT_D2_ORIG_DIR="$(mk_gate_dir "$WORK/mut-D2-orig" 0)"
  RC_ORIG=0; bash "$MUT_D2_ORIG_DIR/check-agents.sh" --agents-dir="$MUT_D2_AG" --skills-dir="$SK" >/dev/null 2>&1 || RC_ORIG=$?
  OUT_MUT="$(bash "$MUT_D2_DIR/check-agents.sh" --agents-dir="$MUT_D2_AG" --skills-dir="$SK" 2>&1)"; RC_MUT=$?
  if [ "$RC_ORIG" -eq 0 ] && [ "$RC_MUT" -eq 1 ] && ! echo "$OUT_MUT" | grep -q "Traceback"; then
    okmut D2 "$RC_MUT" 1 "$RC_ORIG" 0
  else
    komut D2 "rc_mutant=1 et rc_original=0, sans Traceback" "rc_mutant=1, rc_original=0" "rc_mutant=$RC_MUT, rc_original=$RC_ORIG :: $OUT_MUT"
  fi
fi

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
