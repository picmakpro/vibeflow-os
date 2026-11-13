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
printf -- '---\nname: nom ~/.claude/z\nmetadata:\n  type: project\n---\ncorps\n' > "$L3/.claude/agent-memory/vf-coder/a.md" 2>/dev/null || { mkdir -p "$L3/.claude/agent-memory/vf-coder"; printf -- '---\nname: nom ~/.claude/z\nmetadata:\n  type: project\n---\ncorps\n' > "$L3/.claude/agent-memory/vf-coder/a.md"; }
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

# --- FIN-DES-SECTIONS ---
echo
echo "Résultat : $PASS passés, $FAIL échoués"
[ "$FAIL" -eq 0 ]
