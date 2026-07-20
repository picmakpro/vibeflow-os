#!/usr/bin/env bash
# guard-agent-write.sh — Hook PreToolUse(Write) : un agent NON NATIF ne peut plus être écrit
# dans .claude/agents/ (ADR-044). Ce qui passait : agents sans description (jamais routés),
# sans model, sans memory — l'init posait des coquilles vides et personne ne le voyait.
#
# Câblage (posé automatiquement par l'install du module conductor) :
#   PreToolUse · matcher "Write" · command: bash .claude/scripts/guard-agent-write.sh
#
# Règle : Write vers .claude/agents/<nom>.md (hors contracts.md/README.md/AGENTS.md — les
# sous-dossiers *-references/ ne matchent pas) → le CONTENU proposé est validé par
# check-agents.sh --file AVANT écriture. Socle bloquant : frontmatter présent, name,
# description, model, memory + enums valides. Le deny renvoie les erreurs précises + le
# squelette canonique. Portée : LAB COURANT uniquement (un agent hors cwd — perso user-level
# ou autre projet — n'est jamais dénié par la doctrine de ce lab).
#
# Limites ASSUMÉES (garde anti-accident, pas anti-adversaire — audit S061) : Edit/Bash non
# guardés (contenu partiel — rattrapés par le check SessionStart + Gate C) ; Write de contenu
# vide accepté (coquille rattrapée au SessionStart suivant) ; variantes de casse de chemin
# non matchées sur FS insensible à la casse.
#
# Fail-open : toute erreur interne → allow (exit 0 silencieux). Un rc≠0 du checker SANS
# diagnostic lisible (✗) = crash interne → allow aussi (jamais de deny aveugle).

set -uo pipefail

command -v python3 >/dev/null 2>&1 || exit 0

# Préfiltre pur-bash (latence : ce hook tourne sur CHAQUE Write du lab) : le deny n'est
# possible que si file_path pointe sous .claude/agents → tout payload concerné contient la
# sous-chaîne '.claude' (surensemble strict, séparateurs / et \\ inclus). Sinon : 0 spawn.
INPUT="$(cat 2>/dev/null || true)"
case "$INPUT" in
  *'.claude'*) : ;;
  *) exit 0 ;;
esac

printf '%s' "$INPUT" | CHECKER="$(dirname "$0")/check-agents.sh" VF_GUARD=1 python3 -c "
import json, os, subprocess, sys, tempfile

try:
    payload = json.load(sys.stdin)
except Exception:
    sys.exit(0)

ti = payload.get(\"tool_input\") or {}
fp = (ti.get(\"file_path\") or \"\").replace(\"\\\\\", \"/\")
base = os.path.basename(fp)
parent = os.path.normpath(os.path.dirname(fp)) if fp else \"\"
# Frontière exacte : 'my.claude/agents' ne doit PAS matcher (faux positif de suffixe).
if (not (parent == \".claude/agents\" or parent.endswith(\"/.claude/agents\"))
        or not base.endswith(\".md\")
        or base in (\"contracts.md\", \"README.md\", \"AGENTS.md\")):
    sys.exit(0)

# Portee : la charte VibeFlow (model+memory obligatoires) ne s impose qu au LAB COURANT.
# En install user-scope le hook s applique partout — un agent personnel (~/.claude/agents)
# ou un autre projet ne doit pas etre denie par la doctrine de ce lab.
# realpath des DEUX cotes : getcwd() resout les symlinks mais pas abspath(fp) — sur macOS
# /var → /private/var, un lab sous $TMPDIR serait sinon vu hors de lui-meme (fail-open a tort).
try:
    if not (os.path.realpath(fp) + \"/\").startswith(os.path.realpath(os.getcwd()) + \"/\"):
        sys.exit(0)
except Exception:
    sys.exit(0)

content = ti.get(\"content\") or \"\"
if not content.strip():
    sys.exit(0)

checker = os.environ.get(\"CHECKER\", \"\")
if not os.path.isfile(checker):
    sys.exit(0)

# Le lab cible fournit son propre referentiel de skills (pas le CWD du hook) : un agent
# ecrit dans un autre lab ne doit pas etre juge contre les skills du lab courant.
lab_root = fp.rsplit(\"/.claude/agents/\", 1)[0] if \"/.claude/agents/\" in fp else \"\"
skills_arg = []
if lab_root and os.path.isdir(os.path.join(lab_root, \".claude\", \"skills\")):
    skills_arg = [\"--skills-dir=\" + os.path.join(lab_root, \".claude\", \"skills\")]

with tempfile.TemporaryDirectory() as tmpd:
    target = os.path.join(tmpd, base)
    with open(target, \"w\", encoding=\"utf-8\") as f:
        f.write(content)
    try:
        r = subprocess.run([\"bash\", checker, \"--file\", target] + skills_arg,
                           capture_output=True, text=True, timeout=20)
    except Exception:
        sys.exit(0)
    if r.returncode == 0:
        sys.exit(0)
    detail = \" ; \".join(l.strip() for l in r.stdout.splitlines() if \"✗\" in l and \" : \" in l)
    # Anti-trappe : rc!=0 SANS diagnostic lisible = crash interne du checker (pas un lint
    # echoue) → fail-open. Un vrai echec de lint produit toujours des lignes '✗ … : …'.
    if not detail:
        sys.exit(0)

reason = (
    \"Agent NON NATIF refuse (ADR-044) — corrige le frontmatter avant d ecrire. \"
    + (detail[:700] if detail else \"frontmatter non conforme\")
    + \" | Squelette canonique obligatoire : --- ; name: <kebab-case = nom du fichier> ; \"
    + \"description: <quand utiliser cet agent — declencheur du routage automatique> ; \"
    + \"model: sonnet|opus|haiku|fable|inherit ; memory: project ; \"
    + \"skills: [<skills EXISTANTS, crees via skill-creator>] ; effort: <optionnel> ; --- \"
    + \"| Verifier : bash .claude/scripts/check-agents.sh --file <fichier>\"
)
print(json.dumps({
    \"hookSpecificOutput\": {
        \"hookEventName\": \"PreToolUse\",
        \"permissionDecision\": \"deny\",
        \"permissionDecisionReason\": reason,
    }
}, ensure_ascii=False))
sys.exit(0)
" 2>/dev/null || exit 0
exit 0
