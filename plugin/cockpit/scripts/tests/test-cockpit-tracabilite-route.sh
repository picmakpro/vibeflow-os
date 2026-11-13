#!/usr/bin/env bash
# test-cockpit-tracabilite-route.sh — la route GET /api/vf/tracabilite, de bout en bout sur le serveur réel (TRAC-10, TRAC-11 ; P76-D-06 à D-12, D-31, D-38)
#   T10.1-T10.2 vue jalon lue dans l'instantané, accès commun · T10.3-T10.4 sept vues, objet inconnu, clé ambiguë
#   T11.1-T11.3 aucun chemin du poste, dégradations par cas, avant la première collecte
# Labs fabriqués dans mktemp (aucun chemin du poste dans les fichiers écrits), HOME jetable, isolation git. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=Alice GIT_AUTHOR_EMAIL=a@t.test GIT_COMMITTER_NAME=Alice GIT_COMMITTER_EMAIL=a@t.test
export GIT_AUTHOR_DATE="2026-01-15T12:00:00" GIT_COMMITTER_DATE="2026-01-15T12:00:00"
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
TESTS="$SCRIPTS/tests"
mkdir -p "${TMPDIR:-/tmp}"; WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"
AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export HOME="$WORK/home"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || { chmod -R u+rwx "$WORK" 2>/dev/null; rm -rf "$WORK"; }' EXIT
. "$TESTS/hygiene.sh"; vf_hyg_init
. "$TESTS/socle-serveur.sh"

PASS=0; FAIL=0
assert_eq() { if [ "$#" -ne 3 ]; then echo "  ❌ FAIL — $1 (assert_eq : $# arguments au lieu de 3)"; FAIL=$((FAIL+1)); elif [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

# --- outils node écrits par la suite ---
# j.mjs <fichier> <expression sur j> : « absent » si l'expression échoue ou rend undefined, « illisible » si le JSON ne se lit pas
cat > "$AUX/j.mjs" <<'JS'
import fs from 'node:fs';
let j; try { j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')); } catch { console.log('illisible'); process.exit(0); }
let v; try { v = new Function('j', 'return (' + process.argv[3] + ')')(j); } catch { console.log('absent'); process.exit(0); }
console.log(v === undefined ? 'absent' : typeof v === 'string' ? v : JSON.stringify(v));
JS
J() { node "$AUX/j.mjs" "$1" "$2" 2>/dev/null || echo "illisible"; }
# req.mjs <port> <méthode> <chemin> [en-têtes JSON] : { code, h, b } sur une ligne (aucun en-tête ajouté hors de ceux donnés)
cat > "$AUX/req.mjs" <<'JS'
import http from 'node:http';
const [, , port, methode, chemin, entetes] = process.argv;
const r = http.request({ host: '127.0.0.1', port: Number(port), path: chemin, method: methode, headers: JSON.parse(entetes || '{}'), setHost: false }, (res) => {
  let b = ''; res.on('data', (c) => (b += c)); res.on('end', () => console.log(JSON.stringify({ code: res.statusCode, h: res.headers, b })));
});
r.on('error', (e) => console.log(JSON.stringify({ code: 0, h: {}, b: String(e.message) })));
r.end();
JS
# R <méthode> <chemin> [en-têtes JSON] -> $WORK/r.json (hôte et jeton du serveur lancé posés seulement si aucun en-tête n'est donné)
R() { local h="${3:-}"; [ -n "$h" ] || h="{\"Host\":\"127.0.0.1:$VF_PORT\",\"x-vf-cockpit-token\":\"$VF_JETON\"}"; node "$AUX/req.mjs" "$VF_PORT" "$1" "$2" "$h" > "$WORK/r.json" 2>/dev/null; }

# --- fabrication des labs (même fabrication que test-cockpit-tracabilite-collecte.sh) ---
wr() { mkdir -p "$(dirname "$1")"; cat > "$1"; }
lab_base() {
  local d="$1" n="$2" b="$1/.planning/workstreams/x" i; mkdir -p "$b"
  { printf '# Roadmap\n\n## Milestones\n\n- 🚧 **v1** - Phases 1-%s (in progress)\n' "$n"
    printf '\n## Phases\n\n'; for i in $(seq 1 "$n"); do printf -- '- [ ] **Phase %s: P%s** - p\n' "$i" "$i"; done; printf '\n'
    for i in $(seq 1 "$n"); do printf '### Phase %s: P%s\n**Goal**: but %s\n**Depends on**: Nothing\n\n' "$i" "$i" "$i"; done; } > "$b/ROADMAP.md"
  printf -- '---\nmilestone: v1\nstatus: executing\ncurrent_phase: 1\n---\n' > "$b/STATE.md"
}
phdir() { echo "$1/.planning/workstreams/x/phases/$2"; }
ledger() { echo "$1/.planning/workstreams/x/REQUIREMENTS.md"; }
mkplan() { local f="$1" r="$2" extra="${3:-}"; mkdir -p "$(dirname "$f")"; { printf -- '---\nphase: x\nplan: "01"\nwave: 1\n'; [ "$r" = "-" ] || printf 'requirements: %s\n' "$r"; [ -n "$extra" ] && printf '%s\n' "$extra"; printf -- '---\n\n<objective>\nobjectif\n</objective>\n'; } > "$f"; }
mksum() { mkdir -p "$(dirname "$1")"; printf -- '---\n%s\n---\n# Summary\n' "$2" > "$1"; }
G_() { git "$@"; }
# lab L1 : deux phases, deux exigences, un jalon (copie de 76-04)
lab_l1() {
  local L="$1" D1 D2; lab_base "$L" 2
  wr "$(ledger "$L")" <<'MD'
# Exigences

- [x] **REQ-01**: Première exigence
- [ ] **REQ-02**: Deuxième exigence

| REQ-01 | Phase 1 | Complete |
| REQ-02 | Phase 2 | Pending |
MD
  D1="$(phdir "$L" 01-un)"; mkplan "$D1/01-01-PLAN.md" '[REQ-01]'; mksum "$D1/01-01-SUMMARY.md" 'requirements-completed: REQ-01'
  D2="$(phdir "$L" 02-deux)"; mkplan "$D2/02-01-PLAN.md" '[REQ-02]'
}
# lancer_lab <lab> [NOM=valeur…] : lance le serveur réel puis attend la première collecte (vue=jalon sans « collecte »)
pret() { R GET '/api/vf/tracabilite?vue=jalon'; [ "$(J "$WORK/r.json" 'j.code')" = 200 ] && [ "$(J "$WORK/r.json" 'JSON.parse(j.b).collecte')" = absent ]; }
# build_lab <lab> : assemble la sortie du lab (le serveur de la suite lit la page assemblée)
build_lab() { node "$SCRIPTS/vf-cockpit-build.mjs" "$1" --quiet > "$WORK/build.out" 2>&1 || { echo "assemblage KO"; cat "$WORK/build.out"; return 1; }; }
lancer_lab() { local l="$1"; build_lab "$l" && cockpit_lancer "$@" && attendre 20 pret; }

echo "=== T10.1 à T10.2 — vue jalon lue dans l'instantané, derrière les contrôles communs ==="
L1="$WORK/l1"; lab_l1 "$L1"
build_lab "$L1"; cockpit_lancer "$L1"
assert_eq "T10.0 — témoin : le serveur écoute (port et jeton lus)" "$([ "${VF_PORT:-0}" -gt 0 ] && [ "${#VF_JETON}" -ge 16 ] && echo oui || echo non)" "oui"
attendre 20 pret
R GET '/api/vf/tracabilite?vue=jalon'
assert_eq "T10.1 — jalon : 200, schema cockpit-trace@1, etat ok, phases ph-1 et ph-2 avec leur clé" "$(J "$WORK/r.json" "j.code+'|'+(b=>{try{b=JSON.parse(b);return b.schema+'|'+b.etat+'|'+b.jalon.phases.map(p=>p.cle).join()}catch(e){return 'corps-illisible'}})(j.b)")" "200|vibeflow/cockpit-trace@1|ok|ph-1,ph-2"
R GET '/api/vf/tracabilite?vue=jalon' "{\"Host\":\"127.0.0.1:$VF_PORT\"}"
assert_eq "T10.2a — sans jeton : 403" "$(J "$WORK/r.json" 'j.code')" "403"
R POST '/api/vf/tracabilite?vue=jalon'
assert_eq "T10.2b — POST avec jeton : 405" "$(J "$WORK/r.json" 'j.code')" "405"
R GET '/api/vf/inconnu-76'
assert_eq "T10.2c — témoin positif : le même accès sur une route inconnue donne 404 (le 403 de T10.2a vient de l'absence de jeton)" "$(J "$WORK/r.json" 'j.code')" "404"
cockpit_arreter


# --- aides des sections suivantes ---
# Q <paramètres> : GET de la route ; code dans QC, corps dans $WORK/b.json ; JB <expression sur b> lit ce corps
Q() { R GET "/api/vf/tracabilite?$1"; QC="$(J "$WORK/r.json" 'j.code')"; node -e 'process.stdout.write(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).b)' "$WORK/r.json" > "$WORK/b.json" 2>/dev/null || : > "$WORK/b.json"; }
JB() { J "$WORK/b.json" "(b=>($1))(j)"; }
# mutsub.mjs <fichier> <ancre> <remplacement> : copie jetable modifiée ; « muté » exigé en sortie (ancre introuvable = erreur)
cat > "$AUX/mutsub.mjs" <<'JS'
import fs from 'node:fs';
const [, , f, de, vers] = process.argv; const t = fs.readFileSync(f, 'utf8');
if (!t.includes(de)) { console.log('ancre introuvable'); process.exit(1); }
fs.writeFileSync(f, t.split(de).join(vers)); console.log('muté');
JS
# git_lab <lab> : dépôt avec .vibeflow ignoré, tout ce qui existe validé en un commit « init »
git_lab() { printf '.vibeflow/\n' > "$1/.gitignore"; G_ -C "$1" init -q -b main; G_ -C "$1" add -A; G_ -C "$1" commit -q -m init; }
cm() { G_ -C "$1" commit -q --allow-empty -m "$2"; }
# lab L2 : deux phases à registre (90 et 91), un doublon d'identifiant entre registres, ADR, mémoire de deux agents, deux commits citants
lab_l2() {
  local L="$1" B="$1/.planning/workstreams/x"
  lab_base "$L" 1
  printf -- '- [ ] **Phase 90: P90** - p\n\n### Phase 90: P90\n**Goal**: but 90\n**Depends on**: Nothing\n\n- [ ] **Phase 91: P91** - p\n\n### Phase 91: P91\n**Goal**: but 91\n**Depends on**: Nothing\n' >> "$B/ROADMAP.md"
  wr "$B/REQUIREMENTS.md" <<'MD'
# Exigences

- [x] **REQ-01**: Première exigence (P90-D-01, ADR-001, D-04, P95-D-09)
- [ ] **REQ-02**: Deuxième exigence

| REQ-01 | Phase 1 | Complete |
| REQ-02 | Phase 90 | Pending |
MD
  mkplan "$(phdir "$L" 01-un)/01-01-PLAN.md" '[REQ-01]'; mksum "$(phdir "$L" 01-un)/01-01-SUMMARY.md" 'requirements-completed: REQ-01'
  mkplan "$(phdir "$L" 90-x)/90-01-PLAN.md" '[REQ-02]'
  wr "$(phdir "$L" 90-x)/90-CONTEXT.md" <<'MD'
# Contexte

- **P90-D-01** : première définition (ADR-001)
- **D-04** : décision nue
- **P77-D-01** : doublon entre registres
MD
  wr "$(phdir "$L" 91-y)/91-CONTEXT.md" <<'MD'
# Contexte

- **P77-D-01** : doublon de la phase 91
- **P91-D-01** : autre décision
MD
  wr "$L/docs/ADR.md" <<'MD'
# ADR

## ADR-001 — Premier choix

texte

## ADR-002 — Second choix

texte
MD
  wr "$L/.claude/agent-memory/vf-coder/MEMORY.md" <<'MD'
- [A](a.md) — a
MD
  printf -- '---\nname: a-nom\nmetadata:\n  type: project\n---\nVoir [[b-nom]] et [[nulle-part]].\n' > "$L/.claude/agent-memory/vf-coder/a.md"
  printf -- '---\nname: b-nom\nmetadata:\n  type: feedback\n---\ncorps\n' > "$L/.claude/agent-memory/vf-coder/b.md"
  wr "$L/.claude/agent-memory/vf-auditer/MEMORY.md" <<'MD'
- [Z](z.md) — z
MD
  printf -- '---\nname: z-nom\n---\nx\n' > "$L/.claude/agent-memory/vf-auditer/z.md"
  git_lab "$L"; cm "$L" "feat: met en oeuvre P90-D-01 et ADR-001"; cm "$L" "fix: applique D-04 (ADR-002)"
}
# unit.mjs <scripts> <lab> <requête> : appelle lireTracabilite directement (aucune collecte lancée), imprime { corps | code, corps }
cat > "$AUX/unit.mjs" <<'JS'
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, lab, qs] = process.argv;
const T = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-trace.mjs')).href);
const r = await T.lireTracabilite({ root: lab }, null, new URL(`http://x/api/vf/tracabilite?${qs}`));
console.log(JSON.stringify(r && r.code ? { code: r.code, corps: r.corps } : { code: 200, corps: r }));
JS
U() { node "$AUX/unit.mjs" "$SCRIPTS" "$1" "$2" > "$WORK/u.json" 2>/dev/null || echo '{}' > "$WORK/u.json"; }

echo "=== T10.3 à T10.4 — les sept vues, objet inconnu, clé ambiguë (lab L2) ==="
L2="$WORK/l2"; lab_l2 "$L2"
build_lab "$L2"; cockpit_lancer "$L2"; attendre 20 pret
Q 'vue=phase&cle=ph-1'
assert_eq "T10.3a — phase ph-1 : exigences (REQ-01 avec sa clé), bilan, preuves" "$QC|$(JB "b.phase.exigences.map(e=>e.id+':'+e.cle).join()+'|'+b.phase.bilan.total+'|'+Array.isArray(b.phase.preuves)+'|'+b.phase.cle")" "200|REQ-01:REQ-01|1|true|ph-1"
Q 'vue=exigence&cle=REQ-01'
assert_eq "T10.3b — exigence REQ-01 : quatre maillons (plan et SUMMARY lus, VERIFICATION et recette manquantes) et ses sources" "$(JB "Object.keys(b.exigence.maillons).join()+'|'+Object.values(b.exigence.maillons).map(m=>m.etat).join()+'|'+b.exigence.maillons.plan.sources.length+'|'+b.exigence.fichier")" "plan,summary,verification,recette|lu,lu,manque,manque|1|.planning/workstreams/x/REQUIREMENTS.md"
Q 'vue=adr'
assert_eq "T10.3c — adr sans clé : adrs (clé ouvrable) et registres (phases 90 et 91)" "$(JB "b.adrs.map(a=>a.id+':'+a.cle).join()+'|'+b.registres.map(r=>r.phase).join()")" "ADR-001:ADR-001,ADR-002:ADR-002|ph-90,ph-91"
Q 'vue=adr&cle=ADR-001'
assert_eq "T10.3d — adr ADR-001 : sa décision citée et son commit citant (h7, jour, sujet)" "$(JB "b.adr.decisions.map(d=>d.cle).join()+'|'+b.commits.length+'|'+/^[0-9a-f]{7}$/.test(b.commits[0].h7)+'|'+b.commits[0].jour+'|'+b.commits[0].sujet")" "P90-D-01:ph-90|1|true|2026-01-15|feat: met en oeuvre P90-D-01 et ADR-001"
Q 'vue=decision&cle=P90-D-01:ph-90'
assert_eq "T10.3e — décision préfixée : phase ph-90, ADR citée, un commit" "$(JB "b.decision.phase+'|'+b.decision.adrs.map(a=>a.id).join()+'|'+b.commits.length+'|'+b.decision.nue")" "ph-90|ADR-001|1|false"
Q 'vue=decision&cle=D-04:ph-90'
assert_eq "T10.3f — décision nue : commits [] et nue true (jamais reliée, ADR-075)" "$(JB "JSON.stringify(b.commits)+'|'+b.decision.nue")" "[]|true"
Q 'vue=memoire'
assert_eq "T10.3g — memoire : agents et compteurs (huit clés de P76-D-23 et P77)" "$(JB "b.memoire.agents.map(a=>a.agent).join()+'|'+Object.keys(b.memoire.compteurs).sort().join()")" "vf-auditer,vf-coder|agents,cheminsAbsents,entrees,entreesCitantAbsent,horsIndex,liensCasses,resolusParNom,sansEntrant"
assert_eq "T10.3h — compteurs de L2 : trois entrées, deux agents, b.md hors index, un lien cassé" "$(JB "[b.memoire.compteurs.entrees,b.memoire.compteurs.agents,b.memoire.compteurs.horsIndex,b.memoire.compteurs.liensCasses].join()")" "3,2,1,1"
Q 'vue=memoire&cle=vf-coder'
assert_eq "T10.3i — memoire de l'agent vf-coder : ses entrées avec leur clé" "$(JB "b.agent.entrees.map(e=>e.cle).join()")" "vf-coder/a.md,vf-coder/b.md"
Q 'vue=entree&cle=vf-coder/a.md'
assert_eq "T10.3j — fiche de l'entrée a.md : name, type, lien résolu, lien cassé, chemin relatif" "$(JB "[b.entree.name,b.entree.type,b.entree.sortants.map(s=>s.cible+'='+s.etat).join('+'),b.entree.chemin].join('|')")" "a-nom|project|b-nom=resolu+nulle-part=casse|.claude/agent-memory/vf-coder/a.md"
Q 'vue=exigence&cle=ZZZ-99'
assert_eq "T10.4a — exigence inconnue : 200 et etat absent" "$QC|$(JB 'b.etat')" "200|absent"
Q 'vue=decision&cle=P90-D-01'
assert_eq "T10.4b — identifiant préfixé seul et unique : 200, clé canonique rendue" "$QC|$(JB 'b.etat+"|"+b.decision.cle')" "200|ok|P90-D-01:ph-90"
Q 'vue=decision&cle=P77-D-01'
assert_eq "T10.4c — identifiant défini dans deux registres sans :ph-… : 400 cle-ambigue, jamais un choix" "$QC|$(JB 'b.erreur')" "400|cle-ambigue"
Q 'vue=decision&cle=P77-D-01:ph-91'
assert_eq "T10.4d — témoin positif : le même identifiant qualifié par sa phase : 200" "$QC|$(JB 'b.decision.phase')" "200|ph-91"
Q 'vue=phase&cle=ph-404'
assert_eq "T10.4e — phase inconnue : 200 et etat absent" "$QC|$(JB 'b.etat')" "200|absent"
cockpit_arreter

echo "=== T11.1 — aucun chemin du poste dans les sept vues (lab L3) ==="
L3="$WORK/l3"; lab_l1 "$L3"
mkplan "$(phdir "$L3" 01-un)/01-01-PLAN.md" '[REQ-01]' $'must_haves:\n  truths:\n    - "écrit /private/tmp/x"'
wr "$L3/docs/ADR.md" <<MD
# ADR

## ADR-001 — Choix dans $L3/src et $HOME/x

texte
MD
mkdir -p "$L3/.claude/agent-memory/vf-coder"; printf -- '---\nname: nom ~/.claude/z\nmetadata:\n  type: project\n---\ncorps\n' > "$L3/.claude/agent-memory/vf-coder/a.md"
printf -- '- [A](a.md) — a\n' > "$L3/.claude/agent-memory/vf-coder/MEMORY.md"
git_lab "$L3"; cm "$L3" "feat: ADR-001 voir ~/.claude/x et $HOME/y"
tout() { : > "$1"; local qs; for qs in "vue=jalon" "vue=phase&cle=ph-1" "vue=exigence&cle=REQ-01" "vue=adr" "vue=adr&cle=ADR-001" "vue=memoire" "vue=memoire&cle=vf-coder" "vue=entree&cle=vf-coder/a.md"; do Q "$qs"; cat "$WORK/b.json" >> "$1"; echo >> "$1"; done; }
fuite() { [ "$(grep -cF -e "$L3" -e "$HOME" -e '~/' -e '/private/' "$1")" = 0 ] && echo propre || echo fuite; }
build_lab "$L3"; cockpit_lancer "$L3"; attendre 20 pret
tout "$WORK/t111.txt"
assert_eq "T11.1 — aucune des huit réponses ne contient le chemin du lab, \$HOME, ~/ ni /private/" "$(fuite "$WORK/t111.txt")" "propre"
assert_eq "T11.1b — témoin positif : les quatre chaînes sont bien dans les fichiers et messages du lab" "$(grep -cF "$L3/src" "$L3/docs/ADR.md")|$(grep -cF '/private/tmp/x' "$(phdir "$L3" 01-un)/01-01-PLAN.md")|$(G_ -C "$L3" log -1 --format=%s | grep -cF '~/.claude/x')|$(grep -cF '~/.claude/z' "$L3/.claude/agent-memory/vf-coder/a.md")" "1|1|1|1"
assert_eq "T11.1c — témoin positif : les réponses portent bien les textes (titre d'ADR, sujet, critère, nom) remplacés par « un chemin hors du lab »" "$([ "$(grep -c 'un chemin hors du lab' "$WORK/t111.txt")" -ge 3 ] && echo oui || echo non)" "oui"
cockpit_arreter
cockpit_module_muter M-ABSOLU vf-cockpit-trace-texte.mjs "s/^  let t = String(s ?? '');\$/  return String(s ?? '');/" && echo "muté M-ABSOLU"
cockpit_lancer "$L3"; attendre 20 pret
tout "$WORK/t111m.txt"
assert_eq "M-ABSOLU — chemins du poste non retirés (copie jetable de trace-texte) : T11.1 rougit, la sonde voit la fuite" "$(fuite "$WORK/t111m.txt")" "fuite"
cockpit_arreter; unset COCKPIT_MODULE

echo "=== T11.2 — dégradations par cas : 200, l'absence dite, le voisin qui marche ==="
# DA : sans docs/ADR.md et sans mémoire
DA="$WORK/da"; lab_l2 "$DA"; rm -rf "$DA/docs" "$DA/.claude"; G_ -C "$DA" add -A; G_ -C "$DA" commit -q -m "retrait"
build_lab "$DA"; cockpit_lancer "$DA"; attendre 20 pret
Q 'vue=adr'
assert_eq "T11.2a — sans docs/ADR.md : 200, absences.adr vrai, aucune ADR ouvrable (les deux citées par des commits restent sans panneau), registres encore servis" "$QC|$(JB "b.absences.adr+'|'+b.adrs.filter(a=>a.cle!==null).length+'|'+b.registres.length")" "200|true|0|2"
Q 'vue=memoire'
assert_eq "T11.2b — sans .claude/agent-memory/ : 200, absences.memoire absente, aucune entrée" "$QC|$(JB "b.absences.memoire+'|'+b.memoire.compteurs.entrees")" "200|absente|0"
Q 'vue=jalon'
assert_eq "T11.2c — voisin : la vue jalon du même lab est servie avec sa phase" "$QC|$(JB 'b.etat+"|"+b.jalon.phases.length')" "200|ok|1"
cockpit_arreter
# DC : sans compartiment (un .planning sans phase ni compartiment)
DC="$WORK/dc"; mkdir -p "$DC/docs" "$DC/.planning"; printf '# Roadmap\n' > "$DC/.planning/ROADMAP.md"; printf '# ADR\n\n## ADR-001 — Seul choix\n' > "$DC/docs/ADR.md"; git_lab "$DC"
build_lab "$DC"; cockpit_lancer "$DC"; attendre 20 pret
Q 'vue=jalon'
assert_eq "T11.2d — sans compartiment, jalon : 200, etat vide, absences.compartiment vrai" "$QC|$(JB 'b.etat+"|"+b.absences.compartiment')" "200|vide|true"
Q 'vue=phase&cle=ph-1'
assert_eq "T11.2e — sans compartiment, phase : 200, absent, absences.compartiment vrai" "$QC|$(JB 'b.etat+"|"+b.absences.compartiment')" "200|absent|true"
Q 'vue=adr'
assert_eq "T11.2f — voisin : l'ADR du même lab est servie" "$QC|$(JB 'b.adrs.map(a=>a.id).join()')" "200|ADR-001"
cockpit_arreter
# DI : .claude/ ignoré par git, trois fichiers de mémoire non suivis
DI="$WORK/di"; lab_l1 "$DI"; mkdir -p "$DI/.claude/agent-memory/vf-coder"
for n in secret-a secret-b secret-c; do printf -- '---\nname: %s\n---\nx\n' "$n" > "$DI/.claude/agent-memory/vf-coder/$n.md"; done
printf '.vibeflow/\n.claude/\n' > "$DI/.gitignore"; G_ -C "$DI" init -q -b main; G_ -C "$DI" add -A; G_ -C "$DI" commit -q -m init
build_lab "$DI"; cockpit_lancer "$DI"; attendre 20 pret
Q 'vue=memoire'
assert_eq "T11.2g — .claude/ ignoré : absences.memoire ignoree, nonSuivis 3" "$QC|$(JB 'b.absences.memoire+"|"+b.absences.nonSuivis')" "200|ignoree|3"
assert_eq "T11.2h — aucun nom de fichier non suivi dans la réponse ; témoin positif : les trois fichiers existent" "$(grep -c 'secret-' "$WORK/b.json")|$(ls "$DI/.claude/agent-memory/vf-coder" | grep -c secret-)" "0|3"
cockpit_arreter
# DG : sans git
DG="$WORK/dg"; lab_l2 "$DG"; rm -rf "$DG/.git"
build_lab "$DG"; cockpit_lancer "$DG"; attendre 20 pret
Q 'vue=adr&cle=ADR-001'
assert_eq "T11.2i — sans git : 200, absences.git vrai, aucun commit lu, l'ADR (fichier) est servie" "$QC|$(JB "b.absences.git+'|'+b.commits.length+'|'+b.adr.titre")" "200|true|0|Premier choix"
Q 'vue=jalon'
assert_eq "T11.2j — voisin : la vue jalon d'un lab sans git est servie" "$QC|$(JB 'b.etat')" "200|ok"
cockpit_arreter
# DE : ledger rangé en « Étape N »
DE="$WORK/de"; lab_l1 "$DE"
wr "$(ledger "$DE")" <<'MD'
# Exigences

- [x] **REQ-01**: Première exigence
- [ ] **REQ-02**: Deuxième exigence

| REQ-01 | Étape 1 | Complete |
| REQ-02 | Étape 7 | Pending |
MD
build_lab "$DE"; cockpit_lancer "$DE"; attendre 20 pret
Q 'vue=jalon'
assert_eq "T11.2k — ledger en « Étape N » : absences.etapes = { lues 2, sansDossier 1 }, jalon servi" "$QC|$(JB 'JSON.stringify(b.absences.etapes)')" '200|{"lues":2,"sansDossier":1}'
cockpit_arreter

echo "=== T11.3 — avant la première collecte (harnais unitaire, aucune collecte lancée) ==="
U "$L2" 'vue=jalon'
assert_eq "T11.3a — jalon : collecte en-cours, aucune donnée de planning" "$(J "$WORK/u.json" "j.code+'|'+j.corps.collecte+'|'+('jalon' in j.corps)")" "200|en-cours|false"
U "$L2" 'vue=memoire'
assert_eq "T11.3b — memoire : servie (200) avec collecte en-cours, aucune lecture ni git" "$(J "$WORK/u.json" "j.code+'|'+j.corps.collecte+'|'+j.corps.etat")" "200|en-cours|vide"
U "$L2" 'vue=jalon&cle=x'
assert_eq "T11.3c — témoin : la validation précède l'attente de collecte (cle sur jalon : 400)" "$(J "$WORK/u.json" 'j.code')" "400"

echo "=== T10.5 à T10.7, T10.11 — contrôles de C0, contrat, garde d'émission, exigence → décisions (lab L2, serveur réel) ==="
# assert_rouge <nom> <attendu nominal> <obtenu sous mutant> : la sonde du mutant doit s'écarter du nominal ; la trace du rouge est imprimée
assert_rouge() { if [ "$#" -ne 3 ]; then echo "  ❌ FAIL — $1 (assert_rouge : $# arguments au lieu de 3)"; FAIL=$((FAIL+1)); elif [ "$2" != "$3" ]; then echo "  ✅ PASS — $1 (sonde rouge : attendu [$2], obtenu [$3])"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 — le mutant ne rougit pas (obtenu = nominal [$3])"; FAIL=$((FAIL+1)); fi; }
# validate.mjs <interface.json> <sortie.json> : requis typés, optionnels déclarés et typés, états, sous-formes, aucun interdit à toute profondeur
cat > "$AUX/validate.mjs" <<'JS'
import fs from 'node:fs';
const [, , ifaceF, outF] = process.argv;
let spec; try { spec = JSON.parse(fs.readFileSync(ifaceF, 'utf8')).schemas['vibeflow/cockpit-trace@1']; } catch { spec = null; }
if (!spec) { console.log('KO schéma absent'); process.exit(1); }
const out = JSON.parse(fs.readFileSync(outF, 'utf8')), errs = [];
const type = (v) => (Array.isArray(v) ? 'array' : v === null ? 'null' : typeof v);
for (const [k, t] of Object.entries(spec.requis)) { if (!(k in out)) errs.push(`requis absent : ${k}`); else if (type(out[k]) !== t) errs.push(`type de ${k}`); }
for (const k of Object.keys(out)) {
  if (k in spec.requis) continue;
  if (!(k in spec.optionnels)) errs.push(`clé non déclarée : ${k}`); else if (type(out[k]) !== spec.optionnels[k]) errs.push(`type de ${k}`);
}
if (out.schema !== 'vibeflow/cockpit-trace@1') errs.push('schema');
if (!spec.etats.includes(out.etat)) errs.push(`état ${out.etat}`);
const sous = (o, forme) => { for (const k of spec[forme].requis) if (!(k in o)) errs.push(`${forme} : ${k} absent`); };
const ligne = (l) => { sous(l, 'ligneExigence'); for (const m of Object.values(l.maillons || {})) sous(m, 'maillon'); };
const entree = (e) => sous(e, 'entreeMemoire');
for (const l of (out.phase && out.phase.exigences) || []) ligne(l);
if (out.exigence) ligne(out.exigence);
for (const c of out.commits || []) sous(c, 'commit');
for (const e of (out.agent && out.agent.entrees) || []) entree(e);
if (out.entree) entree(out.entree);
const deep = (o, f) => { if (o && typeof o === 'object') for (const [k, v] of Object.entries(o)) { f(k); deep(v, f); } };
deep(out, (k) => { if (spec.interdits.includes(k)) errs.push(`interdit présent : ${k}`); });
console.log(errs.length ? 'KO ' + errs.join(' | ') : 'OK');
JS
build_lab "$L2"; cockpit_lancer "$L2"; attendre 20 pret; TOK2="$VF_JETON"
# sonde_cle : trois clés hors motif sur la vue phase -> codes
sonde_cle() { local o="" c; for c in '..%2Fx' 'ph-1%3Bls' "ph-$(printf '9%.0s' $(seq 1 297))"; do Q "vue=phase&cle=$c"; o="$o$QC|"; done; echo "${o%|}"; }
R GET '/api/vf/tracabilite?vue=jalon' "{\"Host\":\"evil.test\",\"x-vf-cockpit-token\":\"$TOK2\"}"
assert_eq "T10.5a — Host faux : 403" "$(J "$WORK/r.json" 'j.code')" "403"
R GET '/api/vf/tracabilite?vue=jalon' "{\"Host\":\"127.0.0.1:$VF_PORT\",\"Origin\":\"http://evil.test\",\"x-vf-cockpit-token\":\"$TOK2\"}"
assert_eq "T10.5b — Origin étrangère : 403" "$(J "$WORK/r.json" 'j.code')" "403"
Q 'vue=zzz'; C1="$QC"; Q 'vue=jalon&cle=x'; C2="$QC"; Q 'vue=phase'; C3="$QC"; Q 'vue=jalon&vue=phase'; C4="$QC"; Q 'vue=jalon&autre=1'; C5="$QC"
assert_eq "T10.5c — vue inconnue, cle sur jalon, cle absente, vue double, paramètre inconnu : cinq 400" "$C1|$C2|$C3|$C4|$C5" "400|400|400|400|400"
assert_eq "T10.5d — cle hors motif (../x, ph-1;ls, 300 caractères) : 400, 400, 400" "$(sonde_cle)" "400|400|400"
Q 'vue=phase&cle=ph-1'; OK1="$QC"; R GET '/api/vf/tracabilite?vue=phase&cle=ph-1'; H200="$(J "$WORK/r.json" "j.h['cache-control']+'|'+j.h['content-type']")"
R GET '/api/vf/tracabilite?vue=zzz'; H400="$(J "$WORK/r.json" "j.h['cache-control']+'|'+j.h['content-type']")"
assert_eq "T10.5e — témoin positif : une clé valide rend 200 ; 200 et 400 portent no-store et application/json" "$OK1|$H200|$H400" "200|no-store|application/json|no-store|application/json"
for q in 'vue=jalon' 'vue=phase&cle=ph-1' 'vue=exigence&cle=REQ-01' 'vue=adr' 'vue=adr&cle=ADR-001' 'vue=decision&cle=P90-D-01:ph-90' 'vue=memoire' 'vue=memoire&cle=vf-coder' 'vue=entree&cle=vf-coder/a.md'; do
  Q "$q"; V="$(node "$AUX/validate.mjs" "$SCRIPTS/vf-cockpit-interface.json" "$WORK/b.json" 2>&1)"; [ "$V" = OK ] || break
done
assert_eq "T10.6 — chaque réponse des sept vues (neuf requêtes) passe le contrat cockpit-trace@1 (requis, optionnels, états, sous-formes, interdits)" "$V ($q)" "OK ($q)"
Q 'vue=exigence&cle=REQ-01'
assert_eq "T10.11a — REQ-01 : décisions citées (ouvrable, définition absente sans clé), ADR citée, une nue comptée jamais reliée" "$(JB "JSON.stringify([b.exigence.decisions,b.exigence.adrs,b.exigence.decisionsNues,b.exigence.aucuneDecisionCitee])")" '[[{"id":"P90-D-01","cle":"P90-D-01:ph-90","phase":"ph-90"},{"id":"P95-D-09","cle":null}],[{"id":"ADR-001","cle":"ADR-001"}],1,false]'
Q 'vue=exigence&cle=REQ-02'
assert_eq "T10.11b — REQ-02 sans citation : aucuneDecisionCitee vrai, aucune décision ni ADR" "$(JB "[b.exigence.aucuneDecisionCitee,b.exigence.decisions.length,b.exigence.adrs.length].join()")" "true,0,0"
assert_eq "T10.11c — témoin positif : la ligne du ledger porte les quatre citations et 90-CONTEXT.md définit P90-D-01 et D-04" "$(grep -c 'P90-D-01, ADR-001, D-04, P95-D-09' "$(ledger "$L2")")|$(grep -c 'P90-D-01\|\*\*D-04' "$(phdir "$L2" 90-x)/90-CONTEXT.md")" "1|2"
Q 'vue=decision&cle=P90-D-01:ph-90'; A="$QC"; Q 'vue=adr&cle=ADR-001'
assert_eq "T10.11d — chaque clé rendue est ouvrable par decision et adr du même lab (200)" "$A|$QC" "200|200"
sonde_exig() { Q 'vue=exigence&cle=REQ-01'; JB "b.exigence.decisions.map(d=>d.id).join()"; }
sonde_piege() { Q 'vue=entree&cle=vf-coder/a.md'; echo "$QC"; }
# piège : la vue entree ajoute une clé « corps » (copie jetable) ; la garde locale doit refuser
cockpit_arreter
cockpit_module_muter PIEGE-CORPS vf-cockpit-trace-vues.mjs 's/{ entree: e }/{ entree: e, corps: "x" }/' && echo "muté PIEGE-CORPS"
cockpit_lancer "$L2"; attendre 20 pret
Q 'vue=entree&cle=vf-coder/a.md'; P1="$QC|$(JB 'b.erreur')"; Q 'vue=memoire'; P2="$QC"
assert_eq "T10.7a — vue piégée (clé corps ajoutée) : 503 emission-refusee ; témoin positif : la vue normale rend 200" "$P1|$P2" "503|emission-refusee|200"
cockpit_arreter; unset COCKPIT_MODULE
COPIE="$(cockpit_module_copie)"; rm -f "$COPIE/scripts/vf-cockpit-interface.json"
U_ILL="$(node "$AUX/unit.mjs" "$COPIE/scripts" "$L2" 'vue=jalon' 2>/dev/null | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const j=JSON.parse(s);console.log(j.code+"|"+(j.corps&&j.corps.erreur))})')"
assert_eq "T10.7b — contrat illisible (copie sans vf-cockpit-interface.json) : 503 emission-refusee, jamais une réponse" "$U_ILL" "503|emission-refusee"
U "$L2" 'vue=jalon'
assert_eq "T10.7c — témoin positif : avec le contrat, la même requête n'est pas refusée" "$(J "$WORK/u.json" 'j.code')" "200"
# mutants M-GARDE (garde locale neutralisée sur la copie piégée), M-CLE, M-NUE-RELIEE-EXIG : un serveur par mutant
cockpit_module_muter M-GARDE vf-cockpit-trace-vues.mjs 's/{ entree: e }/{ entree: e, corps: "x" }/' >/dev/null
echo "muté M-GARDE (piège)"; AN='if (gardeLocale(corps, INTERDITS))'
grep -nF "$AN" "$COCKPIT_MODULE/scripts/vf-cockpit-trace.mjs" > /dev/null && node "$AUX/mutsub.mjs" "$COCKPIT_MODULE/scripts/vf-cockpit-trace.mjs" "$AN" 'if (false)'
cockpit_lancer "$L2"; attendre 20 pret
Q 'vue=entree&cle=vf-coder/a.md'
assert_rouge "M-GARDE — garde locale neutralisée : la vue piégée sort en 200 avec la clé corps (T10.7a)" "503" "$QC"
cockpit_arreter; unset COCKPIT_MODULE
cockpit_module_muter M-CLE vf-cockpit-trace-vues.mjs 's/^  phase: new RegExp.*$/  phase: \/.*\/,/' && echo "muté M-CLE"
cockpit_lancer "$L2"; attendre 20 pret
assert_rouge "M-CLE — motif de cle assoupli en .* : T10.5d rougit" "400|400|400" "$(sonde_cle)"
cockpit_arreter; unset COCKPIT_MODULE
cockpit_module_muter M-NUE-RELIEE-EXIG vf-cockpit-trace-vues.mjs 's/const decisions = x.cites.decisions.flatMap(/const decisions = [...x.cites.decisions, ...x.cites.nues].flatMap(/' && echo "muté M-NUE-RELIEE-EXIG"
cockpit_lancer "$L2"; attendre 20 pret
assert_rouge "M-NUE-RELIEE-EXIG — la décision nue de la ligne d'exigence reliée : T10.11a rougit" "P90-D-01,P95-D-09" "$(sonde_exig)"
cockpit_arreter; unset COCKPIT_MODULE

echo "=== T10.8 — cache par empreinte, calcul unique en vol, aucun parcours du planning (harnais en processus, git factice compteur) ==="
L8="$WORK/l8"; lab_l2 "$L8"
mkdir -p "$WORK/wrap"; GIT_REEL="$(command -v git)"
cat > "$WORK/wrap/git" <<EOS
#!/bin/sh
echo "\$*" >> "\$VF_GIT_JOURNAL"
GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null exec "$GIT_REEL" "\$@"
EOS
chmod +x "$WORK/wrap/git"
# cache.mjs <scripts> <lab> : scénario complet, un objet { checks, k, ... } sur la sortie ; `instantane` injecté et figé, fs espionné AVANT l'import des modules
cat > "$AUX/cache.mjs" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
const [, , scripts, lab] = process.argv, journal = process.env.VF_GIT_JOURNAL, reel = process.env.GIT_REEL;
const acces = []; // chemins du planning touchés par la route
for (const nom of ['lstatSync', 'statSync', 'readdirSync', 'readFileSync', 'opendirSync', 'realpathSync']) {
  const f = fs[nom], w = function (p, ...a) { if (typeof p === 'string' && /[\\/]\.planning([\\/]|$)/.test(p)) acces.push(nom); return f.call(this, p, ...a); };
  fs[nom] = Object.assign(w, f); // les propriétés (realpathSync.native) suivent
}
const imp = (n) => import(pathToFileURL(path.join(scripts, n)).href);
const T = await imp('vf-cockpit-trace.mjs'), { buildProjectGraph } = await imp('vf-cockpit-project.mjs');
const graphe = buildProjectGraph(lab), c = {};
let seq = 7, sig = 'aaaaaaaaaaaaaaaa', projet = graphe;
const inst = () => Object.freeze({ seq, git: Object.freeze({ sig }), projet });
c.fige = inst().seq === inst().seq && inst().git.sig === inst().git.sig && inst().seq === 7;
const get = async (q) => T.lireTracabilite({ root: lab }, null, new URL(`http://x/api/vf/tracabilite?${q}`), { instantane: inst });
const n = () => (fs.existsSync(journal) ? fs.readFileSync(journal, 'utf8').split('\n').filter(Boolean).length : 0);
const toucher = (f, texte, dec) => { if (texte !== null) fs.writeFileSync(f, texte); const t = new Date(Date.now() + dec * 1000); fs.utimesSync(f, t, t); };
const adr = path.join(lab, 'docs', 'ADR.md'), titre = (r) => (r.adrs || []).map((a) => a.titre).join('|');
await get('vue=adr'); // chauffe : premier calcul, caches de configuration remplis
let n0 = n(); toucher(adr, '# ADR\n\n## ADR-001 — Titre B\n', 10); const rB = await get('vue=adr'); c.k = n() - n0; c.k_ge1 = c.k >= 1;
n0 = n(); toucher(adr, '# ADR\n\n## ADR-001 — Titre C\n', 20); const deux = await Promise.all([get('vue=adr'), get('vue=adr')]);
c.vol = n() - n0 === c.k && titre(deux[0]) === 'Titre C' && titre(deux[1]) === 'Titre C';
n0 = n(); await get('vue=adr'); c.stable = n() - n0 === 0;
acces.length = 0; // à partir d'ici : aucune lecture du planning par la route
projet = structuredClone(graphe);
projet.meta.vf.trace.exigences.push({ id: 'REQ-77', ws: 'x', coche: false, phase: '1', phasesParPlan: [], statut: null, fait: false, rattachement: 'table',
  libelle: 'ajoutée', fichier: 'x', cites: { decisions: [], adrs: [], nues: [] } });
seq = 8; n0 = n(); const ph = await get('vue=phase&cle=ph-1');
c.phase = ph.phase.exigences.map((e) => e.id).join() === 'REQ-01,REQ-77' && n() - n0 === 0;
sig = 'bbbbbbbbbbbbbbbb'; n0 = n(); await get('vue=adr'); c.sig = n() - n0 === c.k;
n0 = n(); toucher(adr, '# ADR\n\n## ADR-001 — Titre D\n', 30); const rD = await get('vue=adr'); c.titre = titre(rD) === 'Titre D' && n() - n0 === c.k;
const mem = path.join(lab, '.claude', 'agent-memory', 'vf-coder'), avant = (await get('vue=memoire')).memoire.compteurs.entrees;
fs.writeFileSync(path.join(mem, 'c.md'), '---\nname: c-nom\n---\nx\n'); execFileSync(reel, ['-C', lab, 'add', '.claude/agent-memory/vf-coder/c.md']);
const t = new Date(Date.now() + 40000); fs.utimesSync(mem, t, t);
n0 = n(); const apres = (await get('vue=memoire')).memoire.compteurs.entrees; c.memoire = apres === avant + 1 && n() - n0 === c.k;
const plan = path.join(lab, '.planning', 'workstreams', 'x', 'phases', '01-un', 'extra.txt');
fs.writeFileSync(plan, 'x'); const t2 = new Date(Date.now() + 50000); fs.utimesSync(path.dirname(plan), t2, t2);
n0 = n(); await get('vue=memoire'); c.planning = n() - n0 === 0; c.planningAcces = acces.length === 0;
console.log(JSON.stringify({ checks: c }));
JS
CACHE() { : > "$WORK/git.journal"; local d="$WORK/l8-$1"; rm -rf "$d"; cp -R "$L8" "$d"; VF_GIT_JOURNAL="$WORK/git.journal" GIT_REEL="$GIT_REEL" PATH="$WORK/wrap:$PATH" node "$AUX/cache.mjs" "${2:-$SCRIPTS}" "$d" > "$WORK/cache-$1.json" 2>"$WORK/cache-$1.err" || echo '{"checks":{}}' > "$WORK/cache-$1.json"; }
CK() { J "$WORK/cache-$1.json" "j.checks.$2"; }
VERD() { J "$WORK/cache-$1.json" "['fige','k_ge1','vol','stable','phase','sig','titre','memoire','planning','planningAcces'].map(k=>j.checks[k]).join()"; }
CACHE nominal
assert_eq "T10.8.0 — précondition : instantané figé (deux appels, même seq et même git.sig) et K >= 1 appels git par calcul, mesurés" "$(CK nominal fige)|$(CK nominal k_ge1)" "true|true"
assert_eq "T10.8a — deux requêtes simultanées après une modification de docs/ADR.md : un seul calcul (+K, jamais +2K), les deux servent le nouveau titre" "$(CK nominal vol)" "true"
assert_eq "T10.8b — une troisième requête identique : aucun appel git (aucun rev-parse par requête)" "$(CK nominal stable)" "true"
assert_eq "T10.8c — seq 7 -> 8 avec une exigence ajoutée : la vue phase la reflète, aucun appel git" "$(CK nominal phase)" "true"
assert_eq "T10.8d — git.sig aaaa -> bbbb : la requête suivante recalcule (+K)" "$(CK nominal sig)" "true"
assert_eq "T10.8e — titre d'ADR modifié sans commit : nouveau titre servi (date de docs/ADR.md), +K" "$(CK nominal titre)" "true"
assert_eq "T10.8f — entrée de mémoire ajoutée sans commit : comptée à la requête suivante (date du dossier d'agent), +K" "$(CK nominal memoire)" "true"
assert_eq "T10.8g — fichier ajouté sous .planning/ sans changement de seq : aucun recalcul" "$(CK nominal planning)" "true"
assert_eq "T10.8h — aucun lstat, stat, ni lecture de répertoire ou de fichier sous .planning/ pendant les requêtes (témoin : le harnais écoute fs avant l'import)" "$(CK nominal planningAcces)" "true"
NOM_V="$(VERD nominal)"
mut_cache() { # <NOM> <fichier> <ancre> <remplacement>
  cockpit_module_copie "$WORK/mod-$1" > /dev/null && node "$AUX/mutsub.mjs" "$WORK/mod-$1/scripts/$2" "$3" "$4" | sed "s/^muté$/muté $1/"; CACHE "$1" "$WORK/mod-$1/scripts"
}
mut_cache M-VOL vf-cockpit-trace.mjs 'if (enVol && enVol.emp === emp) return enVol.p;' ''
assert_rouge "M-VOL — partage du calcul retiré : T10.8a rougit" "$NOM_V" "$(VERD M-VOL)"
mut_cache M-EMPREINTE vf-cockpit-trace.mjs 'const parties = [' 'const parties = [snap.seq]; const _ignore = ['
assert_rouge "M-EMPREINTE — empreinte réduite à seq (sans les dates) : T10.8 rougit" "$NOM_V" "$(VERD M-EMPREINTE)"
mut_cache M-SIG vf-cockpit-trace.mjs 'snap.git && snap.git.sig, ' ''
assert_rouge "M-SIG — git.sig retirée de l'empreinte : T10.8d rougit" "$NOM_V" "$(VERD M-SIG)"
mut_cache M-EMPREINTE-PLANNING vf-cockpit-trace.mjs 'const parties = [' 'const parties = [fs.lstatSync(path.join(root, ".planning")).mtimeMs, '
assert_rouge "M-EMPREINTE-PLANNING — parcours des dates de .planning/ ajouté à l'empreinte : la dernière assertion de T10.8 rougit" "$NOM_V" "$(VERD M-EMPREINTE-PLANNING)"

echo "=== T10.9 — borne des commits citants (lab L9, cinq commits citants) ==="
L9="$WORK/l9"; lab_l1 "$L9"; mkdir -p "$L9/docs"; printf '# ADR\n\n## ADR-001 — Choix\n' > "$L9/docs/ADR.md"
git_lab "$L9"; for i in 1 2 3 4 5; do cm "$L9" "feat: suit ADR-001 ($i)"; done
build_lab "$L9"
cockpit_lancer "$L9" VF_COCKPIT_TRACE_MAX_COMMITS=2; attendre 20 pret
Q 'vue=adr&cle=ADR-001'; B2="$(JB 'b.bornes.tronque+"|"+b.commits.length')"
cockpit_arreter
cockpit_lancer "$L9"; attendre 20 pret
Q 'vue=adr&cle=ADR-001'; B1="$(JB 'b.bornes.tronque+"|"+b.commits.length')"
assert_eq "T10.9 — borne abaissée à 2 : bornes.tronque vrai (deux commits servis) ; borne normale : faux (cinq commits)" "$B2 $B1" "true|2 false|5"
cockpit_arreter
cockpit_module_muter M-TRONQUE vf-cockpit-trace-vues.mjs 's/Boolean(modele.bornes.tronque)/false/' && echo "muté M-TRONQUE"
cockpit_lancer "$L9" VF_COCKPIT_TRACE_MAX_COMMITS=2; attendre 20 pret
Q 'vue=adr&cle=ADR-001'
assert_rouge "M-TRONQUE — tronque forcé à faux : T10.9 rougit (réponse bornée donnée pour complète)" "true" "$(JB 'b.bornes.tronque')"
cockpit_arreter; unset COCKPIT_MODULE

echo "=== T10.10 — confinement de la route : lien symbolique suivi par git vers un fichier hors du lab ==="
L10="$WORK/l10"; lab_l1 "$L10"; mkdir -p "$L10/.claude/agent-memory/vf-coder"
printf -- '---\nname: HORS-MARQUEUR-76\n---\nvoir [[HORS-MARQUEUR-76]]\n' > "$WORK/hors.md"
printf -- '---\nname: DANS-LE-LAB-76\n---\ncorps\n' > "$L10/.claude/dedans.md"
ln -s "$WORK/hors.md" "$L10/.claude/agent-memory/vf-coder/lien.md"; ln -s ../../dedans.md "$L10/.claude/agent-memory/vf-coder/voisin.md"
printf -- '- [L](lien.md)\n- [V](voisin.md)\n' > "$L10/.claude/agent-memory/vf-coder/MEMORY.md"
git_lab "$L10"; build_lab "$L10"
sonde_conf() { local f="$WORK/t1010.txt" q; : > "$f"; for q in 'vue=memoire' 'vue=memoire&cle=vf-coder' 'vue=entree&cle=vf-coder/lien.md'; do Q "$q"; cat "$WORK/b.json" >> "$f"; echo >> "$f"; done; grep -c 'HORS-MARQUEUR-76' "$f"; }
cockpit_lancer "$L10"; attendre 20 pret
assert_eq "T10.10a — aucune des trois réponses ne contient le marqueur d'un fichier hors du lab" "$(sonde_conf)" "0"
Q 'vue=entree&cle=vf-coder/lien.md'; E1="$(JB "b.entree.name+'|'+b.entree.nbSortants")"
Q 'vue=entree&cle=vf-coder/voisin.md'; E2="$(JB "b.entree.name")"
assert_eq "T10.10b — l'entrée hors du lab est listée sans name lu ni lien ; témoin positif : le lien voisin vers un fichier du lab est lu (DANS-LE-LAB-76)" "$E1|$E2" "null|0|DANS-LE-LAB-76"
assert_eq "T10.10c — témoin positif : cat du lien dans le shell rend le marqueur" "$(grep -c 'HORS-MARQUEUR-76' "$L10/.claude/agent-memory/vf-coder/lien.md")" "2"
cockpit_arreter
cockpit_module_muter M-CONFINE vf-cockpit-trace.mjs 's/lireConfine(root, () => ({ adr:/((_r, f) => f())(root, () => ({ adr:/' && echo "muté M-CONFINE"
cockpit_lancer "$L10"; attendre 20 pret
assert_rouge "M-CONFINE — lecture hors de lireConfine : le marqueur du fichier hors du lab est servi (T10.10a rougit)" "0" "$(sonde_conf)"
cockpit_arreter; unset COCKPIT_MODULE

# --- FIN-DES-SECTIONS ---
echo
echo "Résultat : $PASS passés, $FAIL échoués"
[ "$FAIL" -eq 0 ]
