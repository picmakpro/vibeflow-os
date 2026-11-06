#!/usr/bin/env bash
# test-cockpit-projet.sh — graphe Projet du cockpit sur tout lab GSD (CKPT-06) : plat au gabarit GSD (P1),
# partitionné (P2), sans liste de jalons avec missions (P3), contrat et absence de nom de compartiment (P4),
# identité d'une phase = (compartiment, numéro) (P5), visite « Par où commencer » (O4 : ne revient pas d'elle-même ; O5 : étape par étape, cible, centrage, texte entier, « Passer », repère, français ; O6 : l'onglet Projet a sa propre visite, tirée de ses données).
# Fixtures écrites par la suite dans mktemp.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home" "$WORK/locks" "$WORK/locks-abs" "$WORK/locks-vide"
# vie d'une mission (VFSG-06, P68-D-29) : HOME jetable ET dossier de scripts explicite hors de toute disposition …/cockpit/scripts,
# portant un faux driver-lock.sh TENU ; sans dossier explicite le conductor voisin du dépôt serait trouvé. Le dossier n'est posé QUE sur les appels
# en processus de Q : le vrai lanceur (vf-cockpit.mjs, section O4) en fait le dossier de scripts du MODULE, il ne doit pas le voir.
export HOME="$WORK/home"
printf '#!/usr/bin/env bash\ncase "$1" in status) echo "{\\"present\\": true, \\"ws\\": \\"\\", \\"stale\\": false, \\"ttl\\": 1800, \\"progress_age_seconds\\": 30}";; orphans) echo "{\\"orphans\\":[]}";; esac\n' > "$WORK/locks/driver-lock.sh"
printf '#!/usr/bin/env bash\ncase "$1" in status) echo "{\\"present\\": false}";; orphans) echo "{\\"orphans\\":[]}";; esac\n' > "$WORK/locks-abs/driver-lock.sh"
chmod +x "$WORK/locks/driver-lock.sh" "$WORK/locks-abs/driver-lock.sh"

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
# --- outils node écrits par la suite (jamais de long node -e) ---
cat > "$AUX/q.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, what, root, home, scriptsDir, extra] = process.argv;
const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
if (what === 'who') { const m = await imp('vf-cockpit-who.mjs'); console.log(JSON.stringify(m.collectWho(root, { home, scriptsDir }))); }
else if (what === 'reveal') { const m = await imp('vf-cockpit-who.mjs'); console.log(JSON.stringify(m.revealDoing(root, extra, { home, scriptsDir }))); }
else if (what === 'project') { const m = await imp('vf-cockpit-project.mjs'); console.log(JSON.stringify(m.buildProjectGraph(root))); }
JS
cat > "$AUX/get.mjs" <<'JS'
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/validate.mjs" <<'JS'
// validate.mjs <interface.json> <schemaId> <sortie.json> — clés requises et typées, clés interdites à toute profondeur
import fs from 'node:fs';
const [, , ifaceF, id, outF] = process.argv;
const spec = JSON.parse(fs.readFileSync(ifaceF, 'utf8')).schemas[id];
const out = JSON.parse(fs.readFileSync(outF, 'utf8'));
const errs = [];
const type = (v) => (Array.isArray(v) ? 'array' : v === null ? 'null' : typeof v);
for (const [k, t] of Object.entries(spec.requis || {})) {
  if (!(k in out)) errs.push(`clé requise absente : ${k}`);
  else if (t !== 'any' && type(out[k]) !== t) errs.push(`type de ${k} : ${type(out[k])} au lieu de ${t}`);
}
if (out.schema !== id) errs.push(`schema = ${out.schema}`);
const deep = (o, f) => { if (o && typeof o === 'object') for (const [k, v] of Object.entries(o)) { f(k); deep(v, f); } };
deep(out, (k) => { if ((spec.interdits || []).includes(k)) errs.push(`clé interdite présente : ${k}`); });
for (const w of out.workers || []) {
  for (const k of spec.travailleur.requis) if (!(k in w)) errs.push(`travailleur ${w.id} : clé ${k} absente`);
  if (!spec.kinds.includes(w.kind)) errs.push(`kind inconnu : ${w.kind}`);
}
for (const s of Object.values(out.sources || {})) if (!spec.etatsSource.includes(s.etat)) errs.push(`état de source inconnu : ${s.etat}`);
for (const n of out.nodes || []) for (const k of spec.noeud?.requis || []) if (!(k in n)) errs.push(`nœud ${n.id} : clé ${k} absente`);
for (const f of out.files || []) for (const k of spec.element?.requis || []) if (!(k in f)) errs.push(`élément ${f.p} : clé ${k} absente`);
for (const l of out.links || []) for (const k of spec.lien?.requis || []) if (!(k in l)) errs.push(`lien : clé ${k} absente`);
for (const k of spec.meta?.requis || []) if (!(k in (out.meta || {}))) errs.push(`meta.${k} absente`);
console.log(errs.length ? 'KO ' + errs.join(' | ') : 'OK');
process.exit(errs.length ? 1 : 0);
JS
Q() { VF_COCKPIT_SCRIPTS_DIR="${VF_PIN:-$WORK/locks}" node "$AUX/q.mjs" "$SCRIPTS" "$@"; }
G() { node "$AUX/get.mjs" "$@"; }
IFACE="$SCRIPTS/vf-cockpit-interface.json"
wr() { mkdir -p "$(dirname "$1")"; cat > "$1"; }   # wr <fichier> < contenu
graph() { Q project "$1" > "$2"; }

# ---------- P1 — lab plat au gabarit GSD ----------
L1="$WORK/p1"; B="$L1/.planning"
wr "$B/ROADMAP.md" <<'MD'
# Roadmap

## Milestones

- 🚧 **v1.0 MVP** - Phases 1-2 (in progress)

## Phases

- [x] **Phase 1: Socle** - premier jet
- [ ] **Phase 2: Écran** - second jet

### Phase 1: Socle
**Goal**: Poser le socle
**Depends on**: Nothing (first phase)

### Phase 2: Écran
**Goal**: Poser l'écran
**Depends on**: Phase 1
MD
wr "$B/REQUIREMENTS.md" <<'MD'
- [x] **AUTH-01**: se connecter

| AUTH-01 | Phase 1 | Complete |
MD
wr "$B/STATE.md" <<'MD'
---
status: executing
current_phase: 2
---
MD
wr "$B/phases/01-socle/01-01-PLAN.md" <<'MD'
<objective>Poser le socle</objective>
MD
echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
wr "$B/phases/02-ecran/02-01-PLAN.md" <<'MD'
<objective>Poser l'écran</objective>
MD
graph "$L1" "$WORK/g1.json"
echo "=== P1 — lab plat au gabarit GSD ==="
assert_eq "P1.1 — ph-1 done, ph-2 todo (le STATE ne pilote plus le statut : aucun plan fait en phase 2, CKPT-18)" "$(G "$WORK/g1.json" 'j.nodes.filter(n=>/^ph-\d$/.test(n.id)).map(n=>n.id+":"+n.st).join(",")')" "ph-1:done,ph-2:todo"
assert_eq "P1.2 — plan 01-01 done, 02-01 todo (aucun nœud running ne le désigne, CKPT-18)" "$(G "$WORK/g1.json" 'j.files.filter(f=>/^0\d-01 /.test(f.name)).map(f=>f.name.slice(0,5)+":"+f.st).join(",")')" "01-01:done,02-01:todo"
assert_eq "P1.3 — lien ph-1 vers ph-2 de type import" "$(G "$WORK/g1.json" 'j.links.filter(l=>l.a==="n:ph-1"&&l.b==="n:ph-2"&&l.k==="import").length')" "1"
assert_eq "P1.4 — exigence AUTH-01 sous ph-1.req" "$(G "$WORK/g1.json" 'j.files.filter(f=>f.n==="ph-1.req").map(f=>f.name).join(",")')" "AUTH-01"
assert_eq "P1.5 — jalon v1.0 MVP actif, pied « 1 clos · 0 à recetter · 1 à faire · 50 % » (CKPT-16)" "$(G "$WORK/g1.json" 'j.nodes.filter(n=>n.id==="ms-v1.0-mvp").map(n=>n.st+"|"+n.foot).join(",")')" "active|1 clos · 0 à recetter · 1 à faire · 50 %"
assert_eq "P1.6 — meta.vf.phase = 2" "$(G "$WORK/g1.json" 'j.meta.vf.phase')" "2"

# ---------- P2 — lab partitionné, deux compartiments, numéros uniques ----------
L2="$WORK/p2"; B="$L2/.planning"
wr "$B/workstreams/alpha/ROADMAP.md" <<'MD'
## Milestones

- 🚧 **alpha-v1** — Phases 10-11 (en cours)

## Phases

- [ ] Phase 10: Un
- [ ] Phase 11: Deux

### Phase 10: Un
**Goal:** le but
MD
wr "$B/workstreams/beta/ROADMAP.md" <<'MD'
## Milestones

- 🚧 **beta-v1** — Phases 20 (en cours)

## Phases

- [ ] Phase 20: Trois
MD
echo alpha > "$B/active-workstream"
printf -- '---\nmilestone: alpha-v1\ncurrent_phase: 10\nstatus: executing\n---\n' | wr "$B/workstreams/alpha/STATE.md"
wr "$B/workstreams/alpha/phases/VFDO-10-x/10-01-PLAN.md" <<'MD'
<objective>Un plan</objective>
MD
graph "$L2" "$WORK/g2.json"
echo "=== P2 — lab partitionné ==="
assert_eq "P2.1 — les deux jalons sont présents" "$(G "$WORK/g2.json" 'j.nodes.filter(n=>n.kind==="jalon").map(n=>n.id).sort().join(",")')" "ms-alpha-v1,ms-beta-v1"
assert_eq "P2.2 — aucun lien d'enchaînement inter-compartiments" "$(G "$WORK/g2.json" 'j.links.filter(l=>l.k==="event").length')" "0"
assert_eq "P2.3 — meta.vf lu dans le STATE du compartiment actif" "$(G "$WORK/g2.json" 'j.meta.vf.milestone')" "alpha-v1"
assert_eq "P2.4 — identifiants de phase restent ph-10, ph-11, ph-20" "$(G "$WORK/g2.json" 'j.nodes.filter(n=>n.kind==="phase").map(n=>n.id).sort().join(",")')" "ph-10,ph-11,ph-20"
assert_eq "P2.5 — le plan du dossier préfixé est rattaché à ph-10" "$(G "$WORK/g2.json" 'j.files.filter(f=>f.n==="ph-10").length')" "1"

# ---------- P3 — lab plat sans jalons, avec missions ----------
L3="$WORK/p3"; B="$L3/.planning"
wr "$B/ROADMAP.md" <<'MD'
- [ ] **Phase 1: Seule** - une phase
MD
wr "$B/missions/MISSION-1.dag.json" <<'JSON'
{"nodes":[{"id":"a","step":"s","deps":[],"status":"blocked"},{"id":"b","step":"s","deps":[],"status":"ready"},{"id":"c","step":"s","deps":[],"status":"running"},{"id":"d","step":"s","deps":[],"status":"done"},{"id":"e","step":"s","deps":[],"status":"failed"}]}
JSON
printf '{"nodes":[' | wr "$B/missions/TRONQUE.dag.json"
graph "$L3" "$WORK/g3.json"; RC3=$?
echo "=== P3 — sans liste de jalons, missions ==="
assert_eq "P3.1 — graphe rendu malgré le DAG tronqué" "$RC3" "0"
assert_eq "P3.2 — jalon synthétique ms-phases « Phases »" "$(G "$WORK/g3.json" 'j.nodes.filter(n=>n.id==="ms-phases").map(n=>n.label).join(",")')" "Phases"
assert_eq "P3.3 — statuts de DAG todo,todo,active,done,blocked" "$(G "$WORK/g3.json" 'j.files.filter(f=>f.n==="dag-MISSION-1").map(f=>f.st).join(",")')" "todo,todo,active,done,blocked"
assert_eq "P3.4 — le DAG tronqué est ignoré" "$(G "$WORK/g3.json" 'j.nodes.filter(n=>n.id==="dag-TRONQUE").length')" "0"

# ---------- P5 — invariant d'identité : deux compartiments à « Phase 1 » ----------
L5="$WORK/p5"; B="$L5/.planning/workstreams"
for w in un deux; do
  wr "$B/$w/ROADMAP.md" <<'MD'
- [ ] **Phase 1: Premiere** - une phase
MD
done
echo ok > /dev/null
wr "$B/un/phases/01-a/01-01-PLAN.md" <<'MD'
<objective>Plan un</objective>
MD
wr "$B/deux/phases/01-b/01-01-PLAN.md" <<'MD'
<objective>Plan deux</objective>
MD
printf -- '- [ ] **UN-01**: exigence un\n\n| UN-01 | Phase 1 | Pending |\n' | wr "$B/un/REQUIREMENTS.md"
printf -- '- [ ] **DEUX-01**: exigence deux\n\n| DEUX-01 | Phase 1 | Pending |\n' | wr "$B/deux/REQUIREMENTS.md"
graph "$L5" "$WORK/g5.json"
echo "=== P5 — identité (compartiment, numéro) ==="
assert_eq "P5.1 — deux phases distinctes" "$(G "$WORK/g5.json" 'j.nodes.filter(n=>n.kind==="phase").map(n=>n.id).sort().join(",")')" "ph-1@deux,ph-1@un"
assert_eq "P5.2 — chaque plan dans son compartiment" "$(G "$WORK/g5.json" 'j.files.filter(f=>f.p.endsWith("PLAN.md")).map(f=>f.n+"="+f.p.split("/")[2]).sort().join(",")')" "ph-1@deux=deux,ph-1@un=un"
assert_eq "P5.3 — chaque exigence dans son compartiment" "$(G "$WORK/g5.json" 'j.files.filter(f=>f.p.startsWith("req/")).map(f=>f.n+"="+f.name).sort().join(",")')" "ph-1@deux.req=DEUX-01,ph-1@un.req=UN-01"

# ---------- P6 — ROADMAP à la française : lu malgré la dérive, dérive détectée, correctif proposé ----------
# Cas réel (lab Scroll-Off, 2026-11-03) : « Phase N : » partout, aucune phase lue, carte vide sans explication.
L6="$WORK/p6"; B="$L6/.planning"
wr "$B/ROADMAP.md" <<'MD'
# Roadmap

## Phases

- [x] **Phase 1 : Socle** — premier jet
- [ ] **Phase 2 : Écran** — second jet

## Phase Details

### Phase 1 : Socle
**Goal**: Poser le socle
**Depends on**: rien · **Parallélisable avec**: Phase 2

### Phase 2 : Écran
**Goal**: Poser l'écran
**Depends on**: Phase 1
MD
wr "$B/STATE.md" <<'MD'
---
milestone: v2.0
status: executing
---
MD
graph "$L6" "$WORK/g6.json"
DR="$SCRIPTS/vf-cockpit-drift.mjs"
echo "=== P6 — dérive de format ==="
assert_eq "P6.1 — « Phase N : » lu : deux phases, ph-1 done" "$(G "$WORK/g6.json" 'j.nodes.filter(n=>n.kind==="phase").map(n=>n.id+":"+n.st).join(",")')" "ph-1:done,ph-2:todo"
assert_eq "P6.2 — « rien · **Parallélisable avec**: Phase 2 » n'est pas une dépendance à 2" "$(G "$WORK/g6.json" 'j.links.filter(l=>l.k==="import").map(l=>l.a+">"+l.b).join(",")')" "n:ph-1>n:ph-2"
assert_eq "P6.3 — règles signalées dans meta.vf.drift" "$(G "$WORK/g6.json" 'j.meta.vf.drift.regles.map(r=>r.regle+":"+r.n).join(",")')" "phase-deux-points:4,depends-on:1,jalons-absents:1,phase-courante-absente:1"
assert_eq "P6.4 — témoin : le lab au gabarit GSD (P1) est conforme" "$(G "$WORK/g1.json" 'j.meta.vf.drift.regles.length')" "0"
git -C "$L6" init -q && git -C "$L6" add -A && git -C "$L6" -c user.email=t@t -c user.name=t commit -qm init
node "$DR" "$L6" --diff > "$WORK/p6.patch"
avant="$(cd "$L6" && git hash-object .planning/ROADMAP.md)"
assert_eq "P6.5 — le détecteur n'écrit rien sur disque" "$(cd "$L6" && git status --porcelain | wc -l | tr -d ' ')|$(cd "$L6" && git hash-object .planning/ROADMAP.md)" "0|$avant"
assert_eq "P6.6 — le correctif proposé s'applique (git apply --check)" "$(git -C "$L6" apply --check "$WORK/p6.patch" && echo ok)" "ok"
git -C "$L6" apply "$WORK/p6.patch"
graph "$L6" "$WORK/g6b.json"
assert_eq "P6.7 — après correctif : reste seulement la phase courante, non devinable" "$(G "$WORK/g6b.json" 'j.meta.vf.drift.regles.map(r=>r.regle).join(",")')" "phase-courante-absente"
assert_eq "P6.8 — après correctif : jalon v2.0 réel, même lecture des phases" "$(G "$WORK/g6b.json" 'j.nodes.filter(n=>n.kind==="jalon").map(n=>n.label).join(",")')|$(G "$WORK/g6b.json" 'j.nodes.filter(n=>n.kind==="phase").map(n=>n.id+":"+n.st).join(",")')" "v2.0|ph-1:done,ph-2:todo"
printf -- '- [ ] Phase 1 sans séparateur\n' | wr "$L6/x/.planning/ROADMAP.md"
assert_eq "P6.9 — phases citées mais illisibles : niveau bloquant" "$(node "$DR" "$L6/x" --json | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).constats.filter(c=>c.niveau==="bloquant").map(c=>c.regle).join(",")))')" "phases-illisibles"

# P6.10-14 — relecture adverse SOBR-04 de v2.75.1 : coupe au champ suivant, gras dans la valeur, « aucune » suivi d'un ordre,
# correctif sur un ROADMAP sans « ## Phases » et sans saut de ligne final, statut de jalon clos
L7="$WORK/p7"; B="$L7/.planning"; mkdir -p "$B"
printf '%s\n' '# Roadmap' '' '- [ ] **Phase 1: Un** - a' '- [ ] **Phase 2: Deux** - b' '- [ ] **Phase 3: Trois** - c' '- [ ] **Phase 4: Quatre** - d' '- [ ] **Phase 5: Cinq** - e' '- [ ] **Phase 6: Six** - f' '- [ ] **Phase 10: Dix** - j' '' \
  '### Phase 3: Trois' '**Depends on**: Phase 1 · **Parallélisable avec**: Phase 2' '' \
  '### Phase 4: Quatre' '**Depends on**: Phase 1 **et Phase 2** (ordre)' '' \
  '### Phase 5: Cinq' '**Depends on**: aucune dépendance de code ; après 4' '' \
  '### Phase 6: Six' '**Depends on:** Phase 3 (la lib de lecture). La Phase 4 en dépend et consommera l objet avancement (P69-D-10).' '### Phase 10: Dix' '**Depends on**: Nothing' > "$B/ROADMAP.md"
printf -- '---\nstatus: milestone_complete\n---\n' > "$B/STATE.md"
graph "$L7" "$WORK/g7.json"
deps() { G "$WORK/g7.json" "j.links.filter(l=>l.k===\"import\"&&l.b===\"n:ph-$1\").map(l=>l.a.slice(5)).sort().join(\",\")"; }
assert_eq "P6.10 — « Phase 1 · **Parallélisable avec**: Phase 2 » : dépend de 1 seulement" "$(deps 3)" "1"
assert_eq "P6.11 — « Phase 1 **et Phase 2** » : le gras ne coupe pas la valeur" "$(deps 4)" "1,2"
assert_eq "P6.12 — « aucune dépendance de code ; après 4 » garde 4" "$(deps 5)" "4"
assert_eq "P6.12b — « Phase 3 (…). La Phase 4 en dépend (P69-D-10) » : dépend de 3 seulement, ni la dépendante 4 ni le 10 d'un identifiant de décision" "$(deps 6)" "3"
assert_eq "P6.13 — statut milestone_complete : pas de phase-courante-absente" "$(G "$WORK/g7.json" 'j.meta.vf.drift.regles.map(r=>r.regle).join(",")')" "depends-on,jalons-absents"
printf '%s' "$(cat "$B/ROADMAP.md")" > "$B/ROADMAP.md"   # sans saut de ligne final
node "$DR" "$L7" --diff > "$WORK/p7.patch"
assert_eq "P6.14 — correctif sans « ## Phases » ni saut final : appliqué, puis conforme" "$( (cd "$L7" && git apply "$WORK/p7.patch") && node "$DR" "$L7" | head -1)" "Format de la planification conforme."

# ---------- P7 — la détection de dérive ne lit aucun fichier non régulier du lab (famille de read(), merge 69 / main v1.0.1) ----------
# Un ROADMAP en tube FIFO ou un STATE lié à /dev/zero ne doit ni bloquer buildProjectGraph ni remplir la mémoire. Enfant node borné par SIGKILL
# (harnais de A14 de test-cockpit-avancement.sh), tubes et liens supprimés dans tous les cas. Mutant : le `read` local non borné de main est rétabli dans une copie.
echo "=== P7 — drift : lecture bornée des fichiers du lab ==="
cat > "$AUX/borne.mjs" <<'JS'
// borne.mjs <ms> <commande node et arguments...> : enfant node borné par une limite de temps (SIGKILL, sans tube) ; une ligne JSON { timedOut, status, out }
import { spawnSync } from 'node:child_process';
const [, , ms, ...args] = process.argv;
const r = spawnSync(process.execPath, args, { timeout: Number(ms), killSignal: 'SIGKILL', encoding: 'utf8', maxBuffer: 64 << 20 });
console.log(JSON.stringify({ timedOut: r.error?.code === 'ETIMEDOUT', status: r.status, out: r.stdout || '' }));
JS
cat > "$AUX/mutsub.mjs" <<'JS'
// mutsub.mjs <fichier> — remplace UNE occurrence exacte de $FROM par $TO dans une COPIE ; "ancre absente" si $FROM n'y est pas
import fs from 'node:fs';
const f = process.argv[2]; const t = fs.readFileSync(f, 'utf8');
if (!t.includes(process.env.FROM)) { console.log('ancre absente'); process.exit(1); }
fs.writeFileSync(f, t.replace(process.env.FROM, () => process.env.TO)); console.log('muté');
JS
mut7() { local d="$WORK/mut-$1"; rm -rf "$d"; mkdir -p "$d"; cp "$SCRIPTS"/*.mjs "$SCRIPTS/vf-cockpit-interface.json" "$d/"; FROM="$3" TO="$4" node "$AUX/mutsub.mjs" "$d/$2"; }
QB7() { node "$AUX/borne.mjs" 6000 "$AUX/q.mjs" "$1" project "$2" > "$WORK/qb7.json"; G "$WORK/qb7.json" "(j.timedOut?\"bloqué\":\"rendu\")+\"|\"+(()=>{try{return JSON.parse(j.out).meta.vf.counts.phases}catch{return \"illisible\"}})()"; }
L70="$WORK/lab-p70"; L71="$WORK/lab-p71"; L72="$WORK/lab-p72"
printf -- '- [ ] **Phase 1: Un** - a\n' | wr "$L70/.planning/ROADMAP.md"; printf '<objective>Plan</objective>\n' | wr "$L70/.planning/phases/01-a/01-01-PLAN.md"; git -C "$L70" init -q
printf -- '- [ ] **Phase 1: Un** - a\n' | wr "$L71/.planning/ROADMAP.md"; printf '<objective>Plan</objective>\n' | wr "$L71/.planning/phases/01-a/01-01-PLAN.md"; git -C "$L71" init -q
printf -- '- [ ] **Phase 1: Un** - a\n' | wr "$L72/.planning/ROADMAP.md"; printf '<objective>Plan</objective>\n' | wr "$L72/.planning/phases/01-a/01-01-PLAN.md"; git -C "$L72" init -q
assert_eq "P7.0 — contrôle positif : sans fichier spécial, le graphe se rend (1 phase, enfant borné)" "$(QB7 "$SCRIPTS" "$L70")" "rendu|1"
mut7 driftlocal vf-cockpit-drift.mjs "import { readPlanning, fm, read } from './vf-cockpit-planning.mjs';" "import { readPlanning, fm } from './vf-cockpit-planning.mjs';
const read = (f) => { try { return fs.readFileSync(f, 'utf8'); } catch { return ''; } };" > "$WORK/ancre-drift.txt"
rm -f "$L71/.planning/ROADMAP.md"; mkfifo "$L71/.planning/ROADMAP.md"
rm -f "$L72/.planning/STATE.md"; ln -s /dev/zero "$L72/.planning/STATE.md"
R71="$(QB7 "$SCRIPTS" "$L71")"; M71="$(QB7 "$WORK/mut-driftlocal" "$L71")"
R72="$(QB7 "$SCRIPTS" "$L72")"
rm -f "$L71/.planning/ROADMAP.md" "$L72/.planning/STATE.md"
assert_eq "P7.1 — un ROADMAP en tube FIFO ne bloque pas le graphe Projet (détection de dérive comprise)" "$R71" "rendu|0"
assert_eq "P7.2 — un STATE lié à /dev/zero ne bloque pas le graphe Projet (non-régression ; stateFile le refuse déjà : seul le tube FIFO du ROADMAP discrimine, P7.1 et P7.3)" "$R72" "rendu|1"
assert_eq "P7.3 — mutant (read local non borné rétabli, ancre présente) : le tube FIFO bloque, détecté" "$(cat "$WORK/ancre-drift.txt")|$M71" "muté|bloqué|illisible"
assert_eq "P7.5 — vf-cockpit-drift.mjs n'a plus de lecture à lui (read partagé de planning)" "$(grep -c 'const read = ' "$SCRIPTS/vf-cockpit-drift.mjs")" "0"

# ---------- P4 — contrat, syntaxe, aucun nom de compartiment de ce dépôt ----------
echo "=== P4 — contrat et généralité ==="
for n in 1 2 3 5 6; do assert_eq "P4.$n — graphe $n conforme au contrat" "$(node "$AUX/validate.mjs" "$IFACE" vibeflow/cockpit-project@1 "$WORK/g$n.json")" "OK"; done
BAD=0; for f in "$SCRIPTS"/vf-cockpit-*.mjs; do node --check "$f" || BAD=$((BAD+1)); done
assert_eq "P4.6 — node --check passe sur chaque .mjs du socle" "$BAD" "0"
printf '%s\n' "const w = 'fiabilite';" > "$WORK/temoin.mjs"
assert_eq "P4.7 — témoin positif : le contrôle de noms voit un nom codé en dur" "$(cat "$WORK/temoin.mjs" | grep -cE 'fiabilite|gouvernance')" "1"
assert_eq "P4.8 — aucun nom de compartiment de ce dépôt dans les sources du socle" "$(cat "$SCRIPTS"/vf-cockpit-*.mjs | grep -cE 'fiabilite|gouvernance')" "0"

# O6 (70-08, UIFN-05, P70-D-02 : arbitrage Samuel, AskUserQuestion session principale, 2026-11-03 ; P70-D-13 : choix du manager) : l'onglet Projet a sa propre visite (champ `tour` du graphe) —
# le jalon, la phase en cours, les missions, au travail — au lieu du repli sur « La base de code ». O6.1 à O6.4 et O6.6 à O6.8 sans navigateur (graphe lu par la CLI) ; O6.5 dans Chrome (plus bas).
echo "=== O6 — la visite propre à l'onglet Projet : contenu du champ tour ==="
L8="$WORK/p8"; B="$L8/.planning"
wr "$B/ROADMAP.md" <<'MD'
# Roadmap

## Milestones

- 🚧 **v1.0 MVP** - Phases 1-2 (in progress)

## Phases

- [x] **Phase 1: Socle** - premier jet
- [ ] **Phase 2: Écran** - second jet

### Phase 1: Socle
**Goal**: Poser le socle

### Phase 2: Écran
**Goal**: Poser l'écran
MD
printf -- '---\nstatus: executing\ncurrent_phase: 2\ncurrent_phase_name: Écran\n---\n' | wr "$B/STATE.md"
wr "$B/phases/01-socle/01-01-PLAN.md" <<'MD'
<objective>Poser le socle</objective>
MD
echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
wr "$B/phases/02-ecran/02-01-PLAN.md" <<'MD'
<objective>Poser l'écran</objective>
MD
wr "$B/missions/MISSION-ECRAN.dag.json" <<'JSON'
{"phase":"2","nodes":[{"id":"a","step":"s","deps":[],"status":"done"},{"id":"b","step":"s","deps":["a"],"status":"running"}]}
JSON
graph "$L8" "$WORK/g8.json"
L9="$WORK/p9"; mkdir -p "$L9/.planning"; graph "$L9" "$WORK/g9.json"
t8() { G "$WORK/g8.json" "$1"; }
assert_eq "O6.1 — un lab GSD complet : le graphe Projet porte une visite d'au moins deux étapes (jalon, phase en cours, missions, au travail)" "$(t8 'j.tour.length>=2')|$(t8 'j.tour.length')" "true|4"
assert_eq "O6.2 — chaque étape vise une carte du graphe (n:<id> existant) ou la racine avec une cible" "$(t8 'j.tour.filter((s)=>!((s.ref==="root"&&s.cible)||j.nodes.some((n)=>"n:"+n.id===s.ref))).map((s)=>s.title).join(",")')" ""
assert_eq "O6.3 — aucune étape ne parle de « La base de code » ni « dans le code »" "$(t8 'j.tour.filter((s)=>/base de code|dans le code|codebase/i.test([s.kicker,s.title,s.note].join(" "))).length')" "0"
assert_eq "O6.4 — sur un lab sans STATE.md, aucune étape avec « ? », « undefined », « null » ni champ vide" "$(G "$WORK/g3.json" 'j.tour.filter((s)=>[s.title,s.note].some((x)=>!x||/\?|undefined|null/.test(x))).length')|$(G "$WORK/g3.json" 'j.tour.length>=2')" "0|true"
assert_eq "O6.6 — les étapes dans l'ordre : le jalon en cours, la phase 2 (statut lisible), la mission, au travail (#vf-lock)" "$(t8 'j.tour.map((s)=>s.ref+(s.cible?"+"+s.cible:"")).join(" ")')" "n:ms-v1.0-mvp n:ph-2 n:dag-MISSION-ECRAN root+#vf-lock"
assert_eq "O6.7 — l'état de la phase est celui de sa CARTE (« en cours » : un plan non fait, une mission vivante ; PU-G-093, ce n'est plus le « en exécution » de STATE.md), sans « périmé » quand STATE.md s'accorde, le jalon dit les phases faites (« 1 sur 2 »), l'étape « au travail » nomme l'onglet Équipe" "$(t8 '[/en cours/.test(j.tour[1].note),!/périmé|en exécution/.test(j.tour[1].note),/1 sur 2/.test(j.tour[0].note),/Équipe/.test(j.tour[3].note)].join(",")')" "true,true,true,true"
assert_eq "O6.8 — un lab sans planning : visite vide (le repli de 70-07 s'applique, sans parler de code)" "$(G "$WORK/g9.json" 'j.tour.length')" "0"

# R1 (lot 6 « Projet », étape PR1 « vérité des états », 2026-11-06 ; arbitrage Samuel, message direct en session principale, 2026-11-06 : toutes les propositions du panel) : PU-G-093, 097, 099, DG-10. Sans navigateur.
echo "=== R1 — vérité des états : une phase dit l'état de sa carte, jalon « Hors jalon », exigences non cochées, exigences sans doublon ==="
# PU-G-093 : STATE.md « ready_to_plan » alors que tous les plans de la phase 2 sont faits (carte « à recetter »)
LR="$WORK/r1"; B="$LR/.planning"
wr "$B/ROADMAP.md" <<'MD'
## Milestones

- 🚧 **v1.0 MVP** - Phases 1-2 (in progress)

## Phases

- [x] **Phase 1: Socle** - premier jet
- [ ] **Phase 2: Écran** - second jet
MD
printf -- '---\nmilestone: v1.0 MVP\nstatus: ready_to_plan\ncurrent_phase: 2\ncurrent_phase_name: Écran\n---\n' | wr "$B/STATE.md"
wr "$B/phases/01-socle/01-01-PLAN.md" <<'MD'
<objective>Socle</objective>
MD
echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
wr "$B/phases/02-ecran/02-01-PLAN.md" <<'MD'
<objective>Écran</objective>
MD
echo ok > "$B/phases/02-ecran/02-01-SUMMARY.md"
graph "$LR" "$WORK/gr1.json"
assert_eq "R1.1 — PU-G-093 : meta.vf.phaseEtat est l'état de la carte (a-recetter) et STATE.md est dit périmé (ready_to_plan contredit)" "$(G "$WORK/gr1.json" 'j.meta.vf.phaseEtat+"|"+j.meta.vf.stateStale+"|"+j.nodes.find(n=>n.id==="ph-2").st')" "a-recetter|true|recette"
assert_eq "R1.2 — PU-G-093 : la visite (étape 2) et le sous-titre disent « à recetter », jamais « prête à planifier » ; la visite signale STATE.md périmé" "$(G "$WORK/gr1.json" '[/à recetter/.test(j.tour[1].note),/STATE\.md semble périmé/.test(j.tour[1].note),/prête/.test(j.tour[1].note+j.project.summary),/phase 2 \(Écran\) · à recetter\./.test(j.project.summary)].join(",")')" "true,true,false,true"
# repli : phase courante introuvable -> le statut de STATE.md, sans accusation de péremption
printf -- '---\nmilestone: v1.0 MVP\nstatus: executing\ncurrent_phase: 9\n---\n' | wr "$B/STATE.md"
graph "$LR" "$WORK/gr1b.json"
assert_eq "R1.3 — PU-G-093 : phase courante introuvable : phaseEtat null, repli sur le statut de STATE.md (« en exécution »), jamais périmé" "$(G "$WORK/gr1b.json" '[j.meta.vf.phaseEtat,j.meta.vf.stateStale,/en exécution/.test(j.project.summary)].join(",")')" ",false,true"
printf -- '---\nmilestone: v1.0 MVP\nstatus: ready_to_plan\ncurrent_phase: 2\ncurrent_phase_name: Écran\n---\n' | wr "$B/STATE.md"
UIV="$SCRIPTS/../skills/cockpit-moteur/assets/ui/00-vibeflow.js"
assert_eq "R1.4 — PU-G-093 / DG-13 : 00-vibeflow.js lit V.phaseEtat pour le bloc « Maintenant », dit STATE.md périmé, et écrit « Dans l'ordre de la feuille de route. » sous « Jalons »" "$(grep -c 'V\.phaseEtat' "$UIV" | awk '{print ($1>=2)?"ok":"ko"}')|$(grep -c 'STATE.md semble périmé' "$UIV")|$(grep -c "Dans l'ordre de la feuille de route\." "$UIV")" "ok|1|1"
# PU-G-099 : un vrai jalon (clos) et deux phases hors jalon, faites
LJ="$WORK/r1j"; B="$LJ/.planning"
wr "$B/ROADMAP.md" <<'MD'
## Milestones

- ✅ **v1.0 MVP** — Phase 1 (livré)

## Phases

- [x] **Phase 1: Socle** - premier jet
- [x] **Phase 2: Annexe** - hors jalon
- [ ] **Phase 3: Suite** - hors jalon
MD
wr "$B/phases/01-socle/01-01-PLAN.md" <<'MD'
<objective>Socle</objective>
MD
echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
graph "$LJ" "$WORK/gj.json"
assert_eq "R1.5 — PU-G-099 : avec un vrai jalon, le groupe des phases sans jalon s'appelle « Hors jalon » (id ms-hors-jalon), plus « Phases »" "$(G "$WORK/gj.json" 'j.nodes.filter(n=>n.kind==="jalon").map(n=>n.id+"="+n.label).sort().join(",")')" "ms-hors-jalon=Hors jalon,ms-v1.0-mvp=v1.0 MVP"
assert_eq "R1.6 — PU-G-099 : « Hors jalon » n'est ni dans meta.vf.milestones, ni dans « Historique » (1 jalon clos, 1 phase), ni jalon mis en avant, ni chaîne « puis »" "$(G "$WORK/gj.json" '[j.meta.vf.milestones.map(m=>m.key).join("+"),j.nodes.find(n=>n.id==="history").foot,j.nodes.find(n=>n.id==="ms-hors-jalon").parent,j.flows[0].title,j.links.filter(l=>l.k==="event"&&(l.a==="n:ms-hors-jalon"||l.b==="n:ms-hors-jalon")).length].join("|")')" "v1.0 MVP|1 jalons · 1 phases||Trajectoire de v1.0 MVP|0"
assert_eq "R1.7 — PU-G-099 : sans aucun jalon, le groupe garde « Phases » (lab P3)" "$(G "$WORK/g3.json" 'j.nodes.filter(n=>n.kind==="jalon").map(n=>n.label).join(",")')|$(G "$WORK/g3.json" 'j.meta.vf.milestones.map(m=>m.key).join(",")')" "Phases|Phases"
# PU-G-097 : phase faite dont des exigences ne sont pas cochées, et phase non faite (inchangée)
LX="$WORK/r1x"; B="$LX/.planning"
wr "$B/ROADMAP.md" <<'MD'
- [x] **Phase 1: Faite** - a
- [ ] **Phase 2: Ouverte** - b
MD
printf -- '- [x] **A-01**: un\n- [ ] **A-02**: deux\n- [ ] **A-03**: trois\n- [x] **B-01**: un\n- [ ] **B-02**: deux\n\n| A-01 | Phase 1 | Complete |\n| A-02 | Phase 1 | Pending |\n| A-03 | Phase 1 | Pending |\n| B-01 | Phase 2 | Complete |\n| B-02 | Phase 2 | Pending |\n' | wr "$B/REQUIREMENTS.md"
graph "$LX" "$WORK/gx.json"
assert_eq "R1.8 — PU-G-097 : phase faite, 2 exigences sur 3 non cochées : « 2 exigences non cochées » (texte neutre), plus « 1/3 exigences » ; phase non faite : « 1/2 exigences » inchangé" "$(G "$WORK/gx.json" '["ph-1","ph-2"].map(i=>j.nodes.find(n=>n.id===i).foot).join("|")')" "2 exigences non cochées|1/2 exigences"
# DG-10 (PU-G-052) : même exigence dans le fichier vivant du compartiment ET dans l'archive de jalon, même phase par la traçabilité
LD="$WORK/r1d"; B="$LD/.planning"
wr "$B/workstreams/alpha/ROADMAP.md" <<'MD'
- [x] **Phase 1: Un** - a
- [ ] **Phase 2: Deux** - b
MD
echo alpha > "$B/active-workstream"
printf -- '- [x] **RND-02**: recherche\n- [ ] **NEW-01**: neuf\n\n| RND-02 | Phase 1 | Complete |\n| NEW-01 | Phase 2 | Pending |\n' | wr "$B/workstreams/alpha/REQUIREMENTS.md"
printf -- '- [x] **RND-02**: recherche\n- [x] **OLD-09**: autre phase\n\n| RND-02 | Phase 1 | Complete |\n| OLD-09 | Phase 5 | Complete |\n' | wr "$B/milestones/v0-REQUIREMENTS.md"
graph "$LD" "$WORK/gd.json"
assert_eq "R1.9 — DG-10 : RND-02 (vivant + archive, même phase) n'est lue qu'UNE fois (RND-02 sous ph-1, jamais en double) ; l'exigence propre à l'archive (OLD-09, phase 5 sans carte) reste comptée : 3 exigences dont 2 cochées" "$(G "$WORK/gd.json" 'j.files.filter(f=>f.p.startsWith("req/")).map(f=>f.name).sort().join(",")')|$(G "$WORK/gd.json" 'j.meta.vf.counts.reqs+"/"+j.meta.vf.counts.reqsDone')" "NEW-01,RND-02|3/2"

# O4 (recette 3, arbitrage Samuel, AskUserQuestion session principale, 2026-11-03) : la visite « Par où commencer » revenait à chaque chargement et recouvrait la réponse. Cause : son « déjà vue » vivait dans le localStorage
# de l'ORIGINE (port compris) et le port du serveur changeait à chaque lancement. Décision (même date, « C : port stable par lab ») : port stable par lab (vf-cockpit-port.mjs), « déjà vue » en localStorage seul,
# par lab (vibeflow-cockpit:visite:<lab>, 75-vf-modele.js), aucun cookie. Serveurs lancés par le VRAI lanceur (vf-cockpit.mjs), plage de ports décalée (VF_COCKPIT_PORT_BASE : 4378 et 4379 tiennent les serveurs de recette).
# Un Chrome, un profil. Cas : visite au premier chargement ; fermée (croix) puis rechargée sur le MÊME port ; fermée (Échap) idem ; passée jusqu'au bout (autre lab) idem ; serveur relancé (même port stable) ;
# bouton qui la rouvre ; aucun cookie. O4.3 (« même lab, AUTRE port ») n'a plus de sens avec le port stable : remplacé par la relance du serveur. Sans navigateur la section est SAUTÉE, jamais comptée comme réussie.
echo "=== O4 — la visite « Par où commencer » ne revient pas d'elle-même : port stable par lab, localStorage seul, aucun cookie ==="
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then echo "  ⊘ O4 SAUTÉ : aucun navigateur (Chrome, Chromium) — la visite par lab n'est PAS vérifiée, non comptée comme réussie"; else
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
SRVPIDS=(); LABS4=()
fin4() { for L in ${LABS4[@]+"${LABS4[@]}"}; do node "$SCRIPTS/vf-cockpit.mjs" stop --lab "$L" >/dev/null 2>&1; done; for p in ${SRVPIDS[@]+"${SRVPIDS[@]}"}; do vf_hyg_stop "$p"; done; vf_hyg_fin; rm -rf "$WORK"; }
trap fin4 EXIT
mklab4() {
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"; printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - deuxième jet\n- [ ] **Phase 3: Fin** - dernier jet\n' > "$B/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"; echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  LABS4+=("$L")
}
# plage décalée : base prise au hasard au-dessus des ports de recette, jamais 4378..4500
export VF_COCKPIT_PORT_BASE=$((30000 + (RANDOM * 11) % 30000))
adr4() { node "$SCRIPTS/vf-cockpit.mjs" open --no-open --lab "$1" | sed -En 's#^Cockpit : (http://127\.0\.0\.1:[0-9]+)/ .*#\1/index.html#p' | head -1; }
pid4() { node "$AUX/get.mjs" "$1/.vibeflow/cockpit/.cache/server.json" 'j.pid' 2>/dev/null || echo 0; }
pref4() { node --input-type=module -e "import('$SCRIPTS/vf-cockpit-port.mjs').then(m=>console.log(m.portPrefere(process.argv[1])))" "$1"; }
# trois labs dont les ports préférés sont éloignés (≥ 25) : jamais de collision, donc jamais de repli, qui rendrait le cas dépendant du hasard des noms de dossier
for i in $(seq 1 80); do L4="$WORK/lab4-$i"; LC4="$WORK/lab4c-$i"; LE4="$WORK/lab4e-$i"; mkdir -p "$L4" "$LC4" "$LE4"; x=$(pref4 "$L4"); y=$(pref4 "$LC4"); z=$(pref4 "$LE4")
  [ $((x>y ? x-y : y-x)) -ge 25 ] && [ $((x>z ? x-z : z-x)) -ge 25 ] && [ $((y>z ? y-z : z-y)) -ge 25 ] && break; done
rmdir "$L4" "$LC4" "$LE4" 2>/dev/null; mklab4 "$L4"; mklab4 "$LC4"; mklab4 "$LE4"
UA="$(adr4 "$L4")"; SRVPIDS+=("$(pid4 "$L4")"); UC="$(adr4 "$LC4")"; SRVPIDS+=("$(pid4 "$LC4")"); UE="$(adr4 "$LE4")"; SRVPIDS+=("$(pid4 "$LE4")")
cat > "$WORK/relance4.sh" <<RELANCE
#!/usr/bin/env bash
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null VF_COCKPIT_PORT_BASE=$VF_COCKPIT_PORT_BASE
for l in "$L4" "$LC4" "$LE4"; do node "$SCRIPTS/vf-cockpit.mjs" stop --lab "\$l" >/dev/null 2>&1; done
op() { node "$SCRIPTS/vf-cockpit.mjs" open --no-open --lab "\$1" | sed -En 's#^Cockpit : (http://127\.0\.0\.1:[0-9]+)/ .*#\1/index.html#p' | head -1; }
c=\$(op "$LC4"); e=\$(op "$LE4"); a=\$(op "$L4"); printf '%s\n%s\n%s\n' "\$a" "\$c" "\$e"
RELANCE
chmod +x "$WORK/relance4.sh"
XV="$(node "$SCRIPTS/tests/chrome-visite.mjs" "$CHROME" "$UA" "$UC" "$UE" "$WORK/relance4.sh")"
SRVPIDS+=("$(pid4 "$L4")" "$(pid4 "$LC4")" "$(pid4 "$LE4")")
[ -n "${DBG:-}" ] && echo "RAW: $XV"
x4() { printf '%s' "$XV" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O4.0 — témoin : deux labs sur deux ports, la mesure a eu lieu sans erreur, le port du lab est celui de l'empreinte" "$([ "$UA" != "$UC" ] && echo distincts)|$(x4 "j.erreur||''")|$([ "${UA##*:}" = "$(node --input-type=module -e "import('$SCRIPTS/vf-cockpit-port.mjs').then(m=>console.log(m.portPrefere(process.argv[1])))" "$L4")/index.html" ] && echo stable)" "distincts||stable"
assert_eq "O4.1 — premier chargement du lab, la visite s'affiche" "$(x4 'j.premiere')" "true"
assert_eq "O4.2 — fermée par la croix, elle ne revient pas au rechargement sur le même port" "$(x4 'j.croix')" "false"
assert_eq "O4.2b — fermée par Échap (troisième lab, vu pour la première fois), elle ne revient pas au rechargement" "$(x4 'j.echap')" "false"
assert_eq "O4.3 — les trois serveurs arrêtés puis relancés dans un autre ordre (même port stable) : elle ne revient pas (page initialisée, lab connu ; adresse identique)" "$(x4 '[j.relance,j.temoins]')|$([ "$(x4 'j.urlRelance')" = "$UA" ] && echo meme-adresse)" "[false,true]|meme-adresse"
assert_eq "O4.4 — le bouton « Par où commencer » la rouvre" "$(x4 'j.bouton')" "true"
assert_eq "O4.5 — un AUTRE lab la voit à son premier chargement (le rangement est par lab, pas global)" "$(x4 'j.autreLab')" "true"
assert_eq "O4.6 — passée jusqu'au bout (autre lab), elle ne revient pas au rechargement" "$(x4 'j.passee')" "false"
assert_eq "O4.7 — aucun cookie posé : document.cookie vide sur chaque page chargée (témoin : au moins 6 relevés)" "$(x4 'j.cookies.filter(Boolean).length')|$(x4 'j.cookies.length>=6')" "0|true"
# O5 (70-07, UIFN-04, P70-D-02 : arbitrage Samuel, AskUserQuestion session principale, 2026-11-03) : la visite « Par où commencer » parcourue étape par étape (chrome-visite-etapes.mjs), sur l'onglet Code d'un lab
# jetable à plusieurs cartes de premier niveau, servi par le vrai lanceur, à 1 440 et 390 px. Une assertion par mesure et par largeur ; l'obtenu liste les ÉTAPES fautives (numéros, vide = aucune).
# O5.1 chaque étape cible un élément (carte sélectionnée, centrée dans une zone libre et non couverte par la carte de visite, ou élément du chrome mis en évidence) · O5.2 texte entier (jamais « … »), carte de visite dans la fenêtre
# O5.3 « Passer » visible à chaque étape · O5.4 repère « n sur N » juste · O5.5 aucun mot anglais témoin.
echo "=== O5 — la visite, étape par étape : cible, centrage, texte entier, « Passer », repère, français ==="
L5="$WORK/lab5"; mkdir -p "$L5"; mklab4 "$L5"
for d in web api db; do mkdir -p "$L5/$d"; for i in 1 2 3; do printf "export const f%s = () => %s;\n" "$i" "$i" > "$L5/$d/m$i.js"; done; done
git -C "$L5" add -A && git -C "$L5" -c user.email=t@t -c user.name=t commit -q -m cartes
U5="$(adr4 "$L5")"; SRVPIDS+=("$(pid4 "$L5")")
X5="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$U5" 1440,390)"
[ -n "${DBG:-}" ] && echo "RAW5: $X5"
x5() { printf '%s' "$X5" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O5.0 — témoin : la mesure a eu lieu sans erreur, au moins trois étapes à chaque largeur" "$(x5 "j.erreur||''")|$(x5 'j.l1440.n>=3&&j.l390.n>=3')" "|true"
for W in 1440 390; do
  f5() { x5 "j.l$W.etapes.filter((e)=>$1).map((e)=>e.i).join(',')"; }
  assert_eq "O5.1 [$W px] — étapes sans cible, hors du centre de la zone libre, recouvertes par la carte de visite ou hors fenêtre" "$(f5 '!e.cible||!e.centre||e.couvert||!e.visible')" ""
  assert_eq "O5.2 [$W px] — étapes dont le texte est coupé, incomplet ou dont la carte de visite sort de la fenêtre" "$(f5 'e.coupe||!e.entier||!e.tient')" ""
  assert_eq "O5.3 [$W px] — étapes sans bouton « Passer » visible" "$(f5 '!e.passer')" ""
  assert_eq "O5.4 [$W px] — étapes dont le repère n'est pas « n sur N » juste" "$(x5 "j.l$W.etapes.filter((e)=>e.repere!==e.i+' sur '+j.l$W.n).map((e)=>e.i).join(',')")" ""
  assert_eq "O5.5 [$W px] — étapes qui montrent un mot anglais (liste de F11)" "$(f5 '!!e.anglais')" ""
done
# O5.6 (correctif 70-07) : même cas, onglet Code : page déjà vue dans le même profil, rechargée, aux deux largeurs
X56="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$U5" 1440,390 recharge)"
x56() { printf '%s' "$X56" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O5.6 — Code, page déjà vue (rechargement) : mesure sans erreur et étapes sans cible, mal centrées, couvertes ou hors fenêtre, aux deux largeurs" "$(x56 "j.erreur||''")|$(x56 '["l1440","r1440","l390","r390"].map((k)=>j[k].etapes.filter((e)=>!e.cible||!e.centre||e.couvert||!e.visible).map((e)=>k+":"+e.i).join(",")).join("")')" "|"
# O6.5 (70-08) : la même visite parcourue dans Chrome sur l'onglet Projet (project.html) d'un lab à jalon, phase en cours, mission : les mesures O5.1 à O5.5 passent sur Projet, quatre étapes, la première est celle du jalon.
echo "=== O6.5 — la visite Projet dans Chrome ==="
L6="$WORK/lab6"; mkdir -p "$L6"; mklab4 "$L6"
printf -- '---\nstatus: executing\ncurrent_phase: 2\n---\n' > "$L6/.planning/STATE.md"
mkdir -p "$L6/.planning/missions"; printf '{"phase":"2","nodes":[{"id":"a","step":"s","deps":[],"status":"running"}]}\n' > "$L6/.planning/missions/MISSION-X.dag.json"
git -C "$L6" add -A && git -C "$L6" -c user.email=t@t -c user.name=t commit -q -m projet
U6="$(adr4 "$L6")"; SRVPIDS+=("$(pid4 "$L6")"); P6="${U6%index.html}project.html"
# un Chrome (donc un profil neuf) par largeur : la visite se mesure à la PREMIÈRE ouverture de la page ; au rechargement d'une page déjà vue dans le même profil, le centrage de la première étape (une carte) dérive (écart consigné dans 70-08-SUMMARY.md)
X61="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P6" 1440)"; X62="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P6" 390)"
X6="$(node -e "const a=JSON.parse(process.argv[1]),b=JSON.parse(process.argv[2]);console.log(JSON.stringify({erreur:a.erreur||b.erreur,...a,...b}))" "$X61" "$X62")"
[ -n "${DBG:-}" ] && echo "RAW6: $X6"
x6() { printf '%s' "$X6" | node "$AUX/get.mjs" /dev/stdin "$1"; }
cat > "$AUX/titres.mjs" <<'JS'
// titres.mjs <chrome> <session.mjs> <url> : titre, kicker et repère de chaque étape de la visite lancée par son API ; une ligne JSON { etapes: [ { kicker, titre, note } ] } ou { erreur }
import { pathToFileURL } from 'node:url';
const [, , chrome, sess, url] = process.argv;
const { executer, pause } = await import(pathToFileURL(sess).href);
await executer(chrome, async (s) => {
  await s.naviguer(url); await s.attendre("document.readyState === 'complete' && !!window.VibeFlowTour && !!document.getElementById('tour-btn')", 'page prête');
  await s.attendre("!!window.__vfModele && !!window.__vfModele.modele", 'lab connu'); await pause(1200);
  await s.ev('window.VibeFlowTour.end()'); await s.ev('window.VibeFlowTour.start()'); await s.attendre('window.VibeFlowTour.active()', 'visite lancée', 15000);
  const etapes = [];
  for (let i = 0; i < 12 && (await s.ev('window.VibeFlowTour.active()')); i++) {
    await pause(400);
    etapes.push(await s.ev("(() => { const c = document.getElementById('tour'); const q = (x) => (c.querySelector(x) || {}).textContent || ''; return { kicker: q('.tk span:last-child'), titre: q('.tt'), note: q('.tn') }; })()"));
    await s.ev("window.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowRight', bubbles: true }))"); await pause(150);
  }
  return { etapes };
});
JS
T6="$(node "$AUX/titres.mjs" "$CHROME" "$SCRIPTS/tests/chrome-session.mjs" "$P6")"
[ -n "${DBG:-}" ] && echo "RAW6T: $T6"
t6() { printf '%s' "$T6" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.5a — témoin : la mesure a eu lieu sans erreur, la visite Projet compte quatre étapes à chaque largeur" "$(x6 "j.erreur||''")|$(x6 'j.l1440.n+","+j.l390.n')" "|4,4"
assert_eq "O6.5b — la première étape est celle du jalon, la dernière « au travail » ; aucune ne dit « base de code »" "$(t6 'j.etapes.length')|$(t6 '/jalon/i.test(((j.etapes[0]||{}).kicker||"")+((j.etapes[0]||{}).titre||""))')|$(t6 '/travail/i.test(((j.etapes[3]||{}).kicker||"")+((j.etapes[3]||{}).titre||""))')|$(t6 'j.etapes.filter((e)=>/base de code|dans le code/i.test(e.kicker+e.titre+e.note)).length')" "4|true|true|0"
for W in 1440 390; do
  f6() { x6 "j.l$W.etapes.filter((e)=>$1).map((e)=>e.i).join(',')"; }
  assert_eq "O6.5c [$W px] — Projet : étapes sans cible, mal centrées, couvertes ou hors fenêtre (O5.1)" "$(f6 '!e.cible||!e.centre||e.couvert||!e.visible')" ""
  assert_eq "O6.5d [$W px] — Projet : texte coupé ou carte hors fenêtre (O5.2)" "$(f6 'e.coupe||!e.entier||!e.tient')" ""
  assert_eq "O6.5e [$W px] — Projet : étapes sans « Passer » (O5.3)" "$(f6 '!e.passer')" ""
  assert_eq "O6.5f [$W px] — Projet : repère « n sur N » faux (O5.4)" "$(x6 "j.l$W.etapes.filter((e)=>e.repere!==e.i+' sur '+j.l$W.n).map((e)=>e.i).join(',')")" ""
  assert_eq "O6.5g [$W px] — Projet : mot anglais (O5.5)" "$(f6 '!!e.anglais')" ""
done
# O6.6 (correctif 70-07, relevé par 70-08) : la visite d'une page DÉJÀ vue dans le même profil Chrome (rechargement) se centre comme au premier chargement. Cause : le fit de 450 ms du démarrage de la visite défaisait
# le centrage d'une première étape qui est une carte (onglet Projet) quand la carte était mesurée tôt ; un profil neuf, plus lent à se poser, masquait le cas. Ici UN Chrome pour les deux largeurs, deux passes chacune (clés l, r).
X66="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P6" 390,1440 recharge)"
[ -n "${DBG:-}" ] && echo "RAW66: $X66"
x66() { printf '%s' "$X66" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.9 — témoin : le rechargement a été mesuré (erreur vide, quatre étapes à chaque passe)" "$(x66 "j.erreur||''")|$(x66 '["l390","r390","l1440","r1440"].map((k)=>j[k].n).join()')" "|4,4,4,4"
for K in l390 r390 l1440 r1440; do
  assert_eq "O6.9 [$K] — Projet, page déjà vue dans le même profil : étapes sans cible, mal centrées, couvertes ou hors fenêtre" "$(x66 "j.$K.etapes.filter((e)=>!e.cible||!e.centre||e.couvert||!e.visible).map((e)=>e.i).join(',')")" ""
done
# O6.11 et O6.12 (correctifs 70-07, juge Playwright de la recette) : sur l'onglet Projet, UN Chrome, 1 440 puis 390 px, option `passer` : O6.11 « Passer » (ou Échap) pendant une étape de carte rend la vue d'avant la visite (même transformation, aucune carte
# de moins dans la fenêtre, aucune carte recouverte par le titre) ; O6.12 le contour d'une étape sur un élément du chrome (« au travail », #vf-lock) survit à la réécriture du className du bouton par la couche live (70-vf-live.js).
# lab à quatorze phases : le jalon est une grande carte, la visite la zoome et la déplace (sur un petit lab elle est déjà en place)
L8="$WORK/lab8"; mkdir -p "$L8"; mklab4 "$L8"
{ printf '# Roadmap\n\n## Jalon démo\n\n'; for i in $(seq 1 14); do printf -- '- [ ] **Phase %s: Étape %s** - jet %s\n' "$i" "$i" "$i"; done; } > "$L8/.planning/ROADMAP.md"
printf -- '---\nstatus: executing\ncurrent_phase: 2\n---\n' > "$L8/.planning/STATE.md"
mkdir -p "$L8/.planning/missions"; printf '{"phase":"2","nodes":[{"id":"a","step":"s","deps":[],"status":"running"}]}\n' > "$L8/.planning/missions/MISSION-X.dag.json"
git -C "$L8" add -A && git -C "$L8" -c user.email=t@t -c user.name=t commit -q -m grand
U8="$(adr4 "$L8")"; SRVPIDS+=("$(pid4 "$L8")"); P8="${U8%index.html}project.html"
X68="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P8" 1440,390 passer)"
[ -n "${DBG:-}" ] && echo "RAW68: $X68"
x68() { printf '%s' "$X68" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.11a — témoin : la mesure a eu lieu sans erreur, avec la vue d'avant et la vue d'après « Passer » aux deux largeurs" "$(x68 "j.erreur||''")|$(x68 '!!(j.p1440&&j.p1440.avant&&j.p1440.apres&&j.p390&&j.p390.avant&&j.p390.apres)')" "|true"
for W in 1440 390; do
  assert_eq "O6.11 [$W px] — « Passer » à l'étape 3 (une carte) rend la vue d'ensemble d'avant la visite, celle que rend « Terminé » (zoom à 2 % près, position à 4 px près, aucune carte de moins dans la fenêtre, aucune de plus recouverte par le titre)" "$(x68 "[j.p$W].map((p)=>Math.abs(p.avant.k-p.apres.k)<=p.avant.k*0.02&&Math.abs(p.avant.x-p.apres.x)<=4&&Math.abs(p.avant.y-p.apres.y)<=4&&p.apres.visibles>=p.avant.visibles&&p.apres.recouvre<=p.avant.recouvre)[0]")" "true"
  assert_eq "O6.12 [$W px] — Projet : le contour de l'étape « au travail » est encore là après la réécriture du className de #vf-lock (étapes dont le contour a disparu)" "$(x68 "j.l$W.etapes.filter((e)=>e.anneau===true).map((e)=>e.i).join(',')")" ""
done
# O6.16 (Q6b, P70-D-23 : Samuel, AskUserQuestion session principale Claude Code, 2026-11-04 : « Tout selon les recos (Recommandé) ») : sous 701 px, la visite zoome une petite carte jusqu'à la rendre lisible (le juge a mesuré 46 x 31 px) : au moins 120 px de large
# à chaque étape de carte à 390 px (le graphe entier n'y borne plus le zoom : il ne tient pas à cette taille ; au-dessus de 701 px le bornage par le graphe entier reste, O6.10).
assert_eq "O6.16 [390 px] — Projet (lab à quatorze phases) : étapes dont la carte ciblée fait moins de 120 px de large (largeur mesurée)" "$(x68 "j.l390.etapes.filter((e)=>e.largeur!=null&&e.largeur<120).map((e)=>e.i+':'+e.largeur+'px').join(',')")" ""
# O6.13 (correctif 70-07, CI Linux de la PR #200 : R20 « #panel recouvre #tour » à 768 px) : la carte de visite ne passe jamais sous le panneau de détail, quelle que soit la largeur de celui-ci (elle dépend des polices et de la plateforme :
# ici le panneau est élargi à 440 px, ce qui rougit sans Linux). Cause : la carte gardait ses 360 px et son côté même quand le panneau s'avançait. L'émulation `pointer: none` de la suite (R8) ne reproduit PAS le cas : R20 reste vert sous Chrome sans pointeur.
X69="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P6" 768,1024 panneau)"
[ -n "${DBG:-}" ] && echo "RAW69: $X69"
x69() { printf '%s' "$X69" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.13a — témoin : la mesure a eu lieu sans erreur, au moins trois étapes à chaque largeur" "$(x69 "j.erreur||''")|$(x69 'j.l768.n>=3&&j.l1024.n>=3')" "|true"
for W in 768 1024; do
  assert_eq "O6.13 [$W px] — Projet, panneau élargi à 440 px : étapes dont la carte de visite recouvre le panneau" "$(x69 "j.l$W.etapes.filter((e)=>e.surPanneau).map((e)=>e.i).join(',')")" ""
done
# O6.14 (correctif 70-07, CI Linux de ddc487ce : R20 « #context recouvre #tour » à 768 px sur Équipe) : la visite ne s'ouvre pas d'elle-même sur l'onglet Équipe, qui n'a aucune visite conçue (P70-D-02 vise Code et Projet ; son graphe
# a `tour: []`, le repli aurait raconté « une base de code » à propos de sessions et de sous-agents). Sous Linux le démarrage d'office l'ouvrait (le rendu y est plus lent : les cartes de l'équipe sont déjà là à ses 700 ms) ; ici on appelle
# start() comme lui, sans argument, ce qui rougit sous macOS. Le bouton « Par où commencer » reste libre de l'ouvrir. Lab avec une session et un sous-agent, HOME jetable.
HEQ="$WORK/home-eq"; LEQ="$WORK/lab-eq"; mkdir -p "$LEQ/src" "$LEQ/.planning/phases/01-socle" "$HEQ/.claude/projects/-lab-eq"
printf 'export const u = () => 1;\n' > "$LEQ/src/util.js"; printf '# Roadmap\n\n## Jalon démo\n\n- [ ] **Phase 1: Socle** - jet\n' > "$LEQ/.planning/ROADMAP.md"; printf '<objective>x</objective>\n' > "$LEQ/.planning/phases/01-socle/01-01-PLAN.md"
git -C "$LEQ" init -q && git -C "$LEQ" add -A && git -C "$LEQ" -c user.email=t@t -c user.name=t commit -q -m init; LABS4+=("$LEQ")
SIDQ=aaaa1111-2222-3333-4444-000000000099; TSQ="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"; DQ="$HEQ/.claude/projects/-lab-eq"; mkdir -p "$DQ/$SIDQ/subagents"
printf '{"type":"user","cwd":"%s","sessionId":"%s","gitBranch":"main","version":"2.1.317","timestamp":"%s","message":{"content":"salut"}}\n{"type":"assistant","cwd":"%s","sessionId":"%s","gitBranch":"main","version":"2.1.317","timestamp":"%s","message":{"content":[{"type":"text","text":"bonjour"}]}}\n' "$LEQ" "$SIDQ" "$TSQ" "$LEQ" "$SIDQ" "$TSQ" > "$DQ/$SIDQ.jsonl"
printf '{"agentType":"vf-coder","isBuiltIn":false,"launchedWithDefaults":false,"description":"tâche synthétique","toolUseId":"toolu_s1","spawnDepth":1,"requestShape":"background","requestNonInteractive":true}' > "$DQ/$SIDQ/subagents/agent-s1.meta.json"
printf '{"type":"user","isSidechain":true,"agentId":"s1","parentUuid":null,"cwd":"%s","sessionId":"%s","gitBranch":"main","version":"2.1.317","timestamp":"%s","message":{"role":"user","content":"mandat synthétique"}}\n' "$LEQ" "$SIDQ" "$TSQ" > "$DQ/$SIDQ/subagents/agent-s1.jsonl"
UEQ="$(HOME="$HEQ" adr4 "$LEQ")"; SRVPIDS+=("$(pid4 "$LEQ")"); PEQ="${UEQ%index.html}equipe.html"
XEQ="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$PEQ" 768 equipe)"
[ -n "${DBG:-}" ] && echo "RAWEQ: $XEQ"
xeq() { printf '%s' "$XEQ" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.14a — témoin : la mesure a eu lieu sans erreur, l'onglet Équipe a au moins deux cartes (une session et un sous-agent)" "$(xeq "j.erreur||''")|$(xeq 'j.e768.cartes>=2')" "|true"
assert_eq "O6.14 — Équipe / 768 px : le démarrage d'office (start() sans argument) n'ouvre pas la visite" "$(xeq 'j.e768.auto')" "false"
assert_eq "O6.14b — Équipe : le bouton « Par où commencer » n'ouvre plus de visite (Samuel, AskUserQuestion session principale Claude Code, 2026-11-04 : « Tout selon les recos (Recommandé) », P70-D-23, Q13a), il est désactivé (aria-disabled) avec une infobulle qui le dit" "$(xeq 'j.e768.manuel')|$(xeq 'j.e768.bouton.aria')|$(xeq '/Équipe/.test(j.e768.bouton.titre)')" "false|true|true"
# O6.15 (CI Linux de 03bada92 : R15.4b « Échap ferme le tiroir » rouge sous Linux, où la visite d'office s'ouvre pendant la mesure) : quand la visite est ouverte, elle est la couche du dessus et capte la première Échap ; le tiroir de détail
# n'est touché ni par l'ouverture de la visite, ni par sa sortie, et la seconde Échap le ferme. Contrat de l'ordre, mesuré à 390 px sur Projet ; R15.4b mesure donc le tiroir visite fermée (test-cockpit-responsive.sh, section R15 seule).
XEC="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P6" 390 echap)"
[ -n "${DBG:-}" ] && echo "RAWEC: $XEC"
xec() { printf '%s' "$XEC" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.15a — témoin : mesure sans erreur, tiroir ouvert par la carte avant la visite, visite démarrée" "$(xec "j.erreur||''")|$(xec 'j.t390.carteOuverte.tiroir')|$(xec 'j.t390.visiteDemarree.tour')" "|true|true"
assert_eq "O6.15 — visite ouverte au-dessus d'un tiroir ouvert : l'ouverture de la visite ne ferme pas le tiroir ; la première Échap ferme la visite et laisse le tiroir ; la seconde ferme le tiroir (tiroir|visite après chaque temps)" "$(xec '[j.t390.visiteDemarree,j.t390.echap1,j.t390.echap2].map((x)=>x.tiroir+"/"+x.tour).join(" ")')" "true/true true/false false/false"
# DIAG : pour chaque étape fautive de O6.17, une ligne compacte de bbox et de polices (aucune assertion ne change ; la CI Linux nous donne ainsi la vraie géométrie)
diag17() { # diag17 <étiquette> <json> <largeur> <clé>
  local l; l="$(printf '%s' "$2" | node "$AUX/get.mjs" /dev/stdin "j.l$3.etapes.filter((e)=>e.surfaces.length||!e.dansZone||!e.tient||!e.toutLibre||e.couvert).map((e)=>'étape '+e.i+' toutLibre='+e.toutLibre+' couvert='+e.couvert+' surfaces='+e.surfaces.join('+')+' '+e.diag).join('\\n')" 2>/dev/null)"
  [ -n "$l" ] && printf '%s\n' "$l" | sed "s/^/     DIAG $1 [$3 px] /"
  return 0
}
# O6.17 (CI Linux de 07e75a54 : R3 « #zoom recouvre #tour » à 800 px ; quatrième instance après #panel, #context et Échap) : la CLASSE de défaut, pas un cas de plus. Visite ouverte par l'API (sans course de calendrier), sur Code et sur Projet,
# à 390, 768, 800, 1 024 et 1 440 px : à CHAQUE étape, la carte de visite ne recouvre aucune surface fixe visible de l'interface (#zoom, #panel, #context, en-tête, #ask et ses avis, contour de la cible).
XS1="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$U5" 390,768,800,1024,1440)"; XS2="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P6" 390,768,800,1024,1440)"
[ -n "${DBG:-}" ] && echo "RAWS: $XS1 $XS2"
xs1() { printf '%s' "$XS1" | node "$AUX/get.mjs" /dev/stdin "$1"; }
xs2() { printf '%s' "$XS2" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.17a — témoin : les deux mesures ont eu lieu sans erreur, au moins deux étapes à chaque largeur" "$(xs1 "j.erreur||''")|$(xs2 "j.erreur||''")|$(xs1 '[390,768,800,1024,1440].every((w)=>j["l"+w].n>=2)')|$(xs2 '[390,768,800,1024,1440].every((w)=>j["l"+w].n>=2)')" "||true|true"
for W in 390 768 800 1024 1440; do
  assert_eq "O6.17 [$W px] — Code : étapes dont la carte de visite recouvre une surface fixe (étape:surfaces)" "$(xs1 "j.l$W.etapes.filter((e)=>e.surfaces.length).map((e)=>e.i+':'+e.surfaces.join('+')).join(' ')")" ""
  diag17 "O6.17 Code" "$XS1" "$W"
  assert_eq "O6.17 [$W px] — Projet : étapes dont la carte de visite recouvre une surface fixe (étape:surfaces)" "$(xs2 "j.l$W.etapes.filter((e)=>e.surfaces.length).map((e)=>e.i+':'+e.surfaces.join('+')).join(' ')")" ""
  diag17 "O6.17 Projet" "$XS2" "$W"
done
# O6.17 passe « police large » (CI Linux de 63efb1e1 : O6.17 à 800 px, R22, R3 à 390 px rougissaient sous Linux, où Chrome tombe sur DejaVu Sans, plus large que les polices de macOS) : la classe de défaut doit être fermée pour TOUTE largeur de police.
# La carte de visite, le titre et les cartes du graphe prennent Verdana puis DejaVu Sans avec un espacement de lettres (le poste ne décide plus de la taille des textes) ; mêmes cinq largeurs, Code et Projet : aucune surface recouverte,
# la carte ciblée entièrement dans la zone libre (marges comprises), la carte de visite dans la fenêtre. Témoin générique, à garder.
XP1="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$U5" 390,768,800,1024,1440 police)"; XP2="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P6" 390,768,800,1024,1440 police)"
[ -n "${DBG:-}" ] && echo "RAWP: $XP1 $XP2"
xp1() { printf '%s' "$XP1" | node "$AUX/get.mjs" /dev/stdin "$1"; }
xp2() { printf '%s' "$XP2" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.17p-a — témoin : les deux mesures en police large ont eu lieu sans erreur, au moins deux étapes à chaque largeur" "$(xp1 "j.erreur||''")|$(xp2 "j.erreur||''")|$(xp1 '[390,768,800,1024,1440].every((w)=>j["l"+w].n>=2)')|$(xp2 '[390,768,800,1024,1440].every((w)=>j["l"+w].n>=2)')" "||true|true"
for W in 390 768 800 1024 1440; do
  assert_eq "O6.17p [$W px] — Code, police large : étapes dont la carte de visite recouvre une surface fixe, dont la carte ciblée sort de la zone libre ou dont la carte de visite sort de la fenêtre" "$(xp1 "j.l$W.etapes.filter((e)=>e.surfaces.length||!e.dansZone||!e.tient).map((e)=>e.i+':'+e.surfaces.join('+')+(e.dansZone?'':' hors-zone')+(e.tient?'':' hors-fenetre')).join(' ')")" ""
  diag17 "O6.17p Code" "$XP1" "$W"
  assert_eq "O6.17p [$W px] — Projet, police large : étapes dont la carte de visite recouvre une surface fixe, dont la carte ciblée sort de la zone libre ou dont la carte de visite sort de la fenêtre" "$(xp2 "j.l$W.etapes.filter((e)=>e.surfaces.length||!e.dansZone||!e.tient).map((e)=>e.i+':'+e.surfaces.join('+')+(e.dansZone?'':' hors-zone')+(e.tient?'':' hors-fenetre')).join(' ')")" ""
  diag17 "O6.17p Projet" "$XP2" "$W"
done
# O6.17d passe « police réelle » : la VRAIE DejaVu Sans (fichiers TTF libres hors dépôt, $VF_DEJAVU_DIR) imposée à toute la page par @font-face, comme le fait fontconfig sous Ubuntu. Sautée, et dite sautée, sans la variable.
if [ -n "${VF_DEJAVU_DIR:-}" ] && [ -f "$VF_DEJAVU_DIR/DejaVuSans.ttf" ]; then
  XD1="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$U5" 390,768,800,1024,1440 dejavu)"; XD2="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P6" 390,768,800,1024,1440 dejavu)"
  xd1() { printf '%s' "$XD1" | node "$AUX/get.mjs" /dev/stdin "$1"; }
  xd2() { printf '%s' "$XD2" | node "$AUX/get.mjs" /dev/stdin "$1"; }
  assert_eq "O6.17d-a — témoin : mesures en DejaVu Sans réelle sans erreur, polices rendues = DejaVu Sans" "$(xd1 "j.erreur||''")|$(xd2 "j.erreur||''")|$(xd2 'j.l800.etapes.every((e)=>/DejaVu Sans/.test(e.diag.split("rendu=")[1]||""))')" "||true"
  for W in 390 768 800 1024 1440; do
    assert_eq "O6.17d [$W px] — Code, DejaVu Sans réelle : étapes dont la carte de visite recouvre une surface fixe ou dont la carte ciblée sort de la zone libre" "$(xd1 "j.l$W.etapes.filter((e)=>e.surfaces.length||!e.dansZone||!e.tient).map((e)=>e.i+':'+e.surfaces.join('+')).join(' ')")" ""
    diag17 "O6.17d Code" "$XD1" "$W"
    assert_eq "O6.17d [$W px] — Projet, DejaVu Sans réelle : étapes dont la carte de visite recouvre une surface fixe ou dont la carte ciblée sort de la zone libre" "$(xd2 "j.l$W.etapes.filter((e)=>e.surfaces.length||!e.dansZone||!e.tient).map((e)=>e.i+':'+e.surfaces.join('+')).join(' ')")" ""
    diag17 "O6.17d Projet" "$XD2" "$W"
  done
else echo "  ⊘ O6.17d SAUTÉ : VF_DEJAVU_DIR absent (DejaVuSans.ttf et DejaVuSans-Bold.ttf hors dépôt) — la passe en police réelle n'est PAS vérifiée, non comptée comme réussie"; fi
# O6.17t passe « titre haut » (CI Linux de 6c75f230 : #context recouvre #tour à 800 px, introuvable avec DejaVu Sans réelle sous macOS) : le bloc titre est rempli d'une description de 600 caractères avant la visite (police, nom de projet long, ce qui en fait
# un titre plus haut que prévu) ; la carte de visite ne doit rien recouvrir, quitte à replier la description pendant la visite. Cinq largeurs, Code et Projet. Témoin générique de géométrie, indépendant de la police du poste.
XT1="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$U5" 390,768,800,1024,1440 titrehaut)"; XT2="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P6" 390,768,800,1024,1440 titrehaut)"
xt1() { printf '%s' "$XT1" | node "$AUX/get.mjs" /dev/stdin "$1"; }
xt2() { printf '%s' "$XT2" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.17t-a — témoin : mesures à titre haut sans erreur, au moins deux étapes à chaque largeur" "$(xt1 "j.erreur||''")|$(xt2 "j.erreur||''")|$(xt1 '[390,768,800,1024,1440].every((w)=>j["l"+w].n>=2)')|$(xt2 '[390,768,800,1024,1440].every((w)=>j["l"+w].n>=2)')" "||true|true"
for W in 390 768 800 1024 1440; do
  assert_eq "O6.17t [$W px] — Code, titre haut : étapes dont la carte de visite recouvre une surface fixe (étape:surfaces)" "$(xt1 "j.l$W.etapes.filter((e)=>e.surfaces.length).map((e)=>e.i+':'+e.surfaces.join('+')).join(' ')")" ""
  diag17 "O6.17t Code" "$XT1" "$W"
  assert_eq "O6.17t [$W px] — Projet, titre haut : étapes dont la carte de visite recouvre une surface fixe (étape:surfaces)" "$(xt2 "j.l$W.etapes.filter((e)=>e.surfaces.length).map((e)=>e.i+':'+e.surfaces.join('+')).join(' ')")" ""
  diag17 "O6.17t Projet" "$XT2" "$W"
done
# O6.18 passe « tangente » (CI Linux de f41cfd25 : R22 « #ask recouvre #tour » à 1 640 px ; diagnostic de la CI : placement jugé libre à 260 px de large, carte rendue 16..276, #ask à partir de 274) : la carte de visite est jugée sur sa bbox AU MOMENT du placement,
# c'est-à-dire pendant son animation d'entrée (98 % de sa taille) ; une surface à 2 px du bord de la carte finie paraît alors à distance et la carte la recouvre une fois posée. Ici #ask, plus haute (avis), est posée à 2 px DANS le bord de la carte
# à sa largeur d'origine, immobile avant la visite. Cinq largeurs ne sont pas utiles : la géométrie est celle de la carte ; 1 024 et 1 440 px, Code et Projet.
XG1="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$U5" 1024,1440 tangent)"; XG2="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P6" 1024,1440 tangent)"
xg1() { printf '%s' "$XG1" | node "$AUX/get.mjs" /dev/stdin "$1"; }
xg2() { printf '%s' "$XG2" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.18a — témoin : mesures tangentes sans erreur, au moins deux étapes à chaque largeur" "$(xg1 "j.erreur||''")|$(xg2 "j.erreur||''")|$(xg1 '[1024,1440].every((w)=>j["l"+w].n>=2)')|$(xg2 '[1024,1440].every((w)=>j["l"+w].n>=2)')" "||true|true"
for W in 1024 1440; do
  assert_eq "O6.18 [$W px] — Code, #ask à 2 px dans le bord de la carte : étapes dont la carte de visite recouvre une surface fixe" "$(xg1 "j.l$W.etapes.filter((e)=>e.surfaces.length).map((e)=>e.i+':'+e.surfaces.join('+')).join(' ')")" ""
  diag17 "O6.18 Code" "$XG1" "$W"
  assert_eq "O6.18 [$W px] — Projet, #ask à 2 px dans le bord de la carte : étapes dont la carte de visite recouvre une surface fixe" "$(xg2 "j.l$W.etapes.filter((e)=>e.surfaces.length).map((e)=>e.i+':'+e.surfaces.join('+')).join(' ')")" ""
  diag17 "O6.18 Projet" "$XG2" "$W"
done
# O6.10 (correctif 70-07, REG-70-01 de 70-VERIFICATION.md) : visite Projet active au premier chargement sur un lab à jalon et à mission, à 1 024 et 1 920 px : la carte ciblée tient dans la zone libre ET aucune carte du graphe ne sort de la zone
# libre à gauche du panneau (critère de R1, chrome-responsive.mjs). Cause : aim() centrait et zoomait la carte sans regarder le reste du graphe, qui débordait sous le panneau ; il ne dézoomait jamais une carte plus large que sa zone.
L7="$WORK/vibeflow-os-un-nom-de-projet-vraiment-tres-long-pour-tester"; mkdir -p "$L7/src" "$L7/.planning/phases/01-socle" "$L7/.planning/phases/02-suite" "$L7/.planning/missions"
printf 'export const u = () => 1;\n' > "$L7/src/util.js"; printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - la suite\n' > "$L7/.planning/ROADMAP.md"
printf '<objective>Faire le socle</objective>\n' > "$L7/.planning/phases/01-socle/01-01-PLAN.md"; echo ok > "$L7/.planning/phases/01-socle/01-01-SUMMARY.md"; printf '<objective>Faire la suite</objective>\n' > "$L7/.planning/phases/02-suite/02-01-PLAN.md"
printf '{"nodes":[{"id":"a","step":"première étape","stage":"","deps":[],"scope":["src/**"],"status":"done"},{"id":"b","step":"seconde étape","stage":"","deps":["a"],"scope":["src/**"],"status":"running"}]}\n' > "$L7/.planning/missions/demo.dag.json"
git -C "$L7" init -q && git -C "$L7" add -A && git -C "$L7" -c user.email=t@t -c user.name=t commit -q -m init; LABS4+=("$L7")
U7="$(adr4 "$L7")"; SRVPIDS+=("$(pid4 "$L7")"); P7="${U7%index.html}project.html"
X7="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P7" 1024)"; X72="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P7" 1920)"
X7="$(node -e "const a=JSON.parse(process.argv[1]),b=JSON.parse(process.argv[2]);console.log(JSON.stringify({erreur:a.erreur||b.erreur,...a,...b}))" "$X7" "$X72")"
[ -n "${DBG:-}" ] && echo "RAW7: $X7"
x7() { printf '%s' "$X7" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O6.10 — témoin : la mesure a eu lieu sans erreur, au moins trois étapes à chaque largeur" "$(x7 "j.erreur||''")|$(x7 'j.l1024.n>=3&&j.l1920.n>=3')" "|true"
for W in 1024 1920; do
  assert_eq "O6.10 [$W px] — Projet : étapes dont la carte ciblée sort de la zone libre, dont une carte du graphe sort de la zone libre à gauche du panneau, ou qui sélectionnent une carte (le panneau doit garder la vue d'ensemble, R5.3)" "$(x7 "j.l$W.etapes.filter((e)=>!e.dansZone||!e.toutLibre||e.selectionne).map((e)=>e.i).join(',')")" ""
done
# O6.19 passe « carte haute » (CI Linux de 83b13be4 puis 6498ed80 : R1 « long / project / 1 024 px : carte : sort de la zone libre (245..692 / libre 0..648) », intermittent, puis O6.19 lui-même à 1 024 px) : garantie de construction, pas un cas de plus.
# Au-dessus de 701 px un état existe toujours : réduire le zoom jusqu'à ce que tout le graphe tienne dans la zone libre (hors panneau, carte de visite, titre, en-tête, barre de question) avec la carte ciblée visible. aim() réduit donc le zoom par
# paliers (jusqu'à 40 % du zoom qui remplit juste la zone libre) au lieu de centrer comme avant. Contraintes poussées plus loin que la CI : carte de visite de 420 px de haut au moins, seule, puis avec une police large, puis avec la vraie DejaVu Sans
# ($VF_DEJAVU_DIR). Lab « nom long » (jalon, mission), Projet, 768, 1 024 et 1 440 px. Mutant (à la main, voir 70-07-RED-TRACE.md) : le repli « centrer comme avant » rétabli rougit à 1 024 et 1 440 px.
for OPT in cartehaute cartehaute,police cartehaute,dejavu; do
  case "$OPT" in *dejavu*) { [ -n "${VF_DEJAVU_DIR:-}" ] && [ -f "$VF_DEJAVU_DIR/DejaVuSans.ttf" ]; } || { echo "  ⊘ O6.19 [$OPT] SAUTÉ : VF_DEJAVU_DIR absent — la passe en police réelle n'est PAS vérifiée, non comptée comme réussie"; continue; };; esac
  XH="$(node "$SCRIPTS/tests/chrome-visite-etapes.mjs" "$CHROME" "$P7" 768,1024,1440 "$OPT")"
  xh() { printf '%s' "$XH" | node "$AUX/get.mjs" /dev/stdin "$1"; }
  assert_eq "O6.19a [$OPT] — témoin : mesure sans erreur, au moins deux étapes à chaque largeur" "$(xh "j.erreur||''")|$(xh '[768,1024,1440].every((w)=>j["l"+w].n>=2)')" "|true"
  for W in 768 1024 1440; do
    assert_eq "O6.19 [$OPT, $W px] — Projet, carte de visite haute : étapes dont une carte du graphe sort de la zone libre à gauche du panneau, ou dont la carte ciblée est recouverte ou hors de sa zone" "$(xh "j.l$W.etapes.filter((e)=>!e.toutLibre||e.couvert||!e.dansZone).map((e)=>e.i).join(',')")" ""
    diag17 "O6.19 $OPT Projet" "$XH" "$W"
  done
done
unset VF_COCKPIT_PORT_BASE
for L in "${LABS4[@]}"; do node "$SCRIPTS/vf-cockpit.mjs" stop --lab "$L" >/dev/null 2>&1; done; for p in "${SRVPIDS[@]}"; do vf_hyg_stop "$p"; done; SRVPIDS=()
vf_hyg_assert
fi

# ---------- P-VIE — la mission abandonnée ou inconnue sur la carte Projet (VFSG-06 ; P68-D-05, P68-D-23) ----------
LV="$WORK/pvie"; B="$LV/.planning"
wr "$B/ROADMAP.md" <<'MD'
- [ ] **Phase 1: Seule** - une phase
MD
wr "$B/phases/01-a/01-01-PLAN.md" <<'MD'
<objective>Plan un</objective>
MD
wr "$B/missions/MISSION-1.dag.json" <<'JSON'
{"nodes":[{"id":"01-01","step":"s","deps":[],"status":"running"},{"id":"b","step":"s","deps":[],"status":"ready"}]}
JSON
git -C "$LV" init -q
VF_PIN="$WORK/locks-abs" graph "$LV" "$WORK/gv-abs.json"
VF_PIN="$WORK/locks-vide" graph "$LV" "$WORK/gv-vide.json"
graph "$LV" "$WORK/gv-tenu.json"
echo "=== P-VIE — mission abandonnée ou inconnue ==="
assert_eq "P-VIE.0 — témoin positif : verrou tenu, la mission reste active et son plan désigné aussi" "$(G "$WORK/gv-tenu.json" 'j.nodes.find(n=>n.id==="dag-MISSION-1").st+"|"+j.files.find(f=>/^01-01 /.test(f.name)).st')" "active|active"
assert_eq "P-VIE.1 — sans verrou : la carte dag-MISSION-1 est todo et son pied dit « abandonnée, nœuds non refermés »" "$(G "$WORK/gv-abs.json" 'j.nodes.find(n=>n.id==="dag-MISSION-1").st+"|"+j.nodes.find(n=>n.id==="dag-MISSION-1").foot.includes("abandonnée, nœuds non refermés")')" "todo|true"
assert_eq "P-VIE.2 — un plan désigné par un nœud running d'une mission abandonnée reste todo" "$(G "$WORK/gv-abs.json" 'j.files.find(f=>/^01-01 /.test(f.name)).st')" "todo"
assert_eq "P-VIE.3 — les détails de la phase disent « Mission : MISSION-1 (abandonnée, nœuds non refermés) »" "$(G "$WORK/gv-abs.json" 'j.nodes.find(n=>n.id==="ph-1").details.includes("Mission : MISSION-1 (abandonnée, nœuds non refermés)")')" "true"
assert_eq "P-VIE.4 — verrous illisibles (aucun script) : la carte est todo et son pied dit « état inconnu »" "$(G "$WORK/gv-vide.json" 'j.nodes.find(n=>n.id==="dag-MISSION-1").st+"|"+j.nodes.find(n=>n.id==="dag-MISSION-1").foot.includes("état inconnu")')" "todo|true"

# P-VIE.5 — couplage socle/UI (68, passe 2) : 00-vibeflow.js réécrit la pastille d'une carte dont le pied dit « abandonnée » (const ABANDON). Le pied vient du socle (LIBELLES_MISSION) :
# si son libellé change, la pastille retomberait sur « À faire » sans bruit. On confronte l'expression de l'UI au pied RÉEL de la sortie du socle, et aux pieds qui ne doivent PAS la déclencher.
cat > "$AUX/abandon.mjs" <<'JS'
// abandon.mjs <00-vibeflow.js> <graphe.json> [<libellé de remplacement du mot « abandonnée »>] : « reconnu|inconnu-ignoré|mutant-ignoré » ou « regex absente »
import fs from 'node:fs';
const [, , ui, g, mut] = process.argv;
const m = /const ABANDON = (\/.*\/);/.exec(fs.readFileSync(ui, 'utf8')); if (!m) { console.log('regex absente'); process.exit(0); }
const re = new Function('return ' + m[1])();
const foot = JSON.parse(fs.readFileSync(g, 'utf8')).nodes.find((n) => n.id === 'dag-MISSION-1').foot;
const f2 = mut ? foot.replace('abandonnée', mut) : foot;
console.log(mut ? String(re.test(f2)) : [re.test(foot), !re.test('1/2 nœuds · état inconnu'), !re.test('1/2 nœuds · en cours'), !re.test('1/2 nœuds')].join('|'));
JS
UI68="$SCRIPTS/../skills/cockpit-moteur/assets/ui/00-vibeflow.js"
assert_eq "P-VIE.5 — l'expression ABANDON de 00-vibeflow.js reconnaît le pied RÉEL d'une mission abandonnée du socle et ignore « état inconnu », « en cours » et le pied nu" "$(node "$AUX/abandon.mjs" "$UI68" "$WORK/gv-abs.json")" "true|true|true|true"
assert_eq "P-VIE.5b — témoin : un libellé du socle changé (« délaissée ») ne serait PAS reconnu : la mesure rougirait" "$(node "$AUX/abandon.mjs" "$UI68" "$WORK/gv-abs.json" délaissée)" "false"

# ---------- P8 — parseurs tolérants (matrice générée) et diagnostic « lignes non comprises » ----------
# Une seule planification porte une phase par variante (produit : gras × deux-points dedans/dehors × espace normal/U+00A0/U+202F/aucune × noms FR/EN/synonymes × casse × puce).
# Preuves : la matrice est rouge sur un mutant qui rétablit l'ancienne regex (et sur le code de 57e7957f) ; le diagnostic est muet sur le gabarit GSD et rouge sur un mutant qui le coupe.
echo "=== P8 — parseurs tolérants et diagnostic ==="
cat > "$AUX/matrice.mjs" <<'JS'
// matrice.mjs <scripts> <travail> : écrit UNE planification plate (une phase par variante), la lit par readPlanning, rend { total, echecs, traces } en JSON
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, work] = process.argv;
const { readPlanning } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-planning.mjs')).href);
const NBSP = ' ', NNBSP = ' ';
const ESPACES = ['', ' ', NBSP, NNBSP];
const CASSES = [(s) => s, (s) => s.toUpperCase(), (s) => s.toLowerCase()];
const FORMES = [(nom, sp) => `**${nom}${sp}:**`, (nom, sp) => `**${nom}**${sp}:`, (nom, sp) => `${nom}${sp}:`];
const PUCES = ['', '- '];
const road = ['# Roadmap', '', '### Phase 1: Racine', '**Goal**: racine', '**Depends on**: Nothing', ''];
const attendus = []; // { id, ok(phases) -> [attendu, obtenu] }
let i = 0;
const ajoute = (id, bloc, verif) => { road.push(...bloc, ''); attendus.push({ id, verif }); };
// dépendances : 3 formes × 4 espaces × 6 noms × 3 casses × 2 puces = 432
for (const nom of ['Depends on', 'Dépend de', 'Dépendances', 'Dépendance', 'Dependencies', 'Depends']) for (const c of CASSES) for (const f of FORMES) for (const sp of ESPACES) for (const p of PUCES) {
  const n = 100 + i++, tete = `${p}${f(c(nom), sp)}`;
  ajoute(`dep ${JSON.stringify(tete)}`, [`### Phase ${n}: Dep${n}`, `${tete} Phase 01 (contexte).`], (ph) => [['1'], ph.get(`|${n}`)?.depends]);
}
// titres : 3 niveaux × 3 formes de numéro × 9 séparateurs × gras ou non = 162
for (const lvl of ['##', '###', '####']) for (const fmt of ['plain', 'pad', 'dec']) for (const sep of [': ', ' : ', ' :', `${NBSP}: `, `${NNBSP}: `, ' — ', ' – ', '—', ' - ']) for (const g of ['', '**']) {
  const n = 1000 + i++, num = fmt === 'plain' ? String(n) : fmt === 'pad' ? String(n).padStart(6, '0') : `${n}.5`, cle = fmt === 'dec' ? `${n}.5` : String(n);
  const ligne = `${lvl} ${g}Phase ${num}${sep}Titre${n}${g}`;
  ajoute(`titre ${JSON.stringify(ligne)}`, [ligne, `**Goal**: but${n}`], (ph) => [`Titre${n}|but${n}`, ph.has(`|${cle}`) ? `${ph.get(`|${cle}`).name}|${ph.get(`|${cle}`).goal}` : 'phase absente']);
}
// Goal / Objectif : 3 noms × 3 formes × 4 espaces × 3 casses × 2 puces = 216
for (const nom of ['Goal', 'Objectif', 'Objective']) for (const c of CASSES) for (const f of FORMES) for (const sp of ESPACES) for (const p of PUCES) {
  const n = 3000 + i++, tete = `${p}${f(c(nom), sp)}`;
  ajoute(`goal ${JSON.stringify(tete)}`, [`### Phase ${n}: But${n}`, `${tete} Livrer ${n}`], (ph) => [`Livrer ${n}`, ph.get(`|${n}`)?.goal]);
}
// cases de phase : 3 cases × 3 puces × gras ou non × 4 espaces × 2 numéros = 144 (le roadmap ci-dessus est écrit dans une section distincte pour ne pas mêler titres et cases)
const cases = [];
for (const box of ['[ ]', '[x]', '[X]']) for (const b of ['-', '*', '+']) for (const g of ['', '**']) for (const sp of ESPACES) for (const z of ['', '0']) {
  const n = 5000 + i++, ligne = `${b} ${box} ${g}Phase ${z}${n}${sp}: Case${n}${g} - description`;
  cases.push(ligne); attendus.push({ id: `case ${JSON.stringify(ligne)}`, verif: (ph) => [`Case${n}|${box !== '[ ]'}`, ph.has(`|${n}`) ? `${ph.get(`|${n}`).name}|${ph.get(`|${n}`).done}` : 'phase absente'] });
}
for (const box of ['[ ]', '[x]', '[X]']) for (const b of ['-', '*', '+']) for (const g of ['', '**']) for (const sep of [' — ', ' – ', ' - ', '—']) {
  const n = 7000 + i++, ligne = `${b} ${box} ${g}Phase ${n}${sep}Tiret${n}${g} - description`;
  cases.push(ligne); attendus.push({ id: `case-tiret ${JSON.stringify(ligne)}`, verif: (ph) => [`Tiret${n}|${box !== '[ ]'}`, ph.has(`|${n}`) ? `${ph.get(`|${n}`).name}|${ph.get(`|${n}`).done}` : 'phase absente'] });
}
const dir = path.join(work, '.planning'); fs.mkdirSync(dir, { recursive: true });
fs.writeFileSync(path.join(dir, 'ROADMAP.md'), ['# Roadmap', '', '## Phases', ...cases, '', ...road.slice(2)].join('\n') + '\n');
// exigences : 4 formes × 3 cases × 2 puces = 24
const reqs = ['# Exigences', '']; let r = 0;
for (const [forme, nom] of [[(id) => `**${id}**:`, 'gras-puis-deux-points'], [(id) => `**${id}:**`, 'deux-points-dans-le-gras'], [(id) => `${id}:`, 'nu'], [(id) => `${id} :`, 'nu-espace']]) for (const box of ['[ ]', '[x]', '[X]']) for (const b of ['-', '*']) {
  const id = `TST-${++r}`; reqs.push(`${b} ${box} ${forme(id)} texte ${id}`);
  attendus.push({ id: `req ${nom} ${box} ${b}`, verif: (ph, rq) => [`texte ${id}|${box !== '[ ]'}`, rq.has(`|${id}`) ? `${rq.get(`|${id}`).text}|${rq.get(`|${id}`).done}` : 'exigence absente'] });
}
fs.writeFileSync(path.join(dir, 'REQUIREMENTS.md'), reqs.join('\n') + '\n');
// statut et phase courante : valeurs entre guillemets, casse, tirets
fs.writeFileSync(path.join(dir, 'STATE.md'), '---\nstatus: "In Progress"\ncurrent_phase: "02"\n---\n');
const P = readPlanning(work, undefined, { sansTags: true });
attendus.push({ id: 'statut « In Progress »', verif: (ph, rq, st) => ['in_progress', st.status] });
attendus.push({ id: 'current_phase « "02" »', verif: (ph, rq, st) => ['02', st.current_phase] });
const echecs = []; for (const a of attendus) { const [att, obt] = a.verif(P.phases, P.reqs, P.state); if (JSON.stringify(att) !== JSON.stringify(obt)) echecs.push(`${a.id} : attendu ${JSON.stringify(att)}, obtenu ${JSON.stringify(obt)}`); }
console.log(JSON.stringify({ total: attendus.length, echecs: echecs.length, traces: echecs.slice(0, 4) }));
JS
node "$AUX/matrice.mjs" "$SCRIPTS" "$WORK/p8m" > "$WORK/mat.json"
assert_eq "P8.1 — matrice : 1052 variantes de dépendances, titres, Goal, cases, exigences, statut (anti-vert-à-vide)" "$(G "$WORK/mat.json" 'j.total')" "1052"
assert_eq "P8.2 — matrice : toutes lues comme attendu ($(G "$WORK/mat.json" 'j.traces.join(" ; ")'))" "$(G "$WORK/mat.json" 'j.echecs')" "0"
mut7 anciennedep vf-cockpit-formats.mjs "const m = DEP_RE.exec(corps); if (!m) return [];" "const m = /\\*\\*(?:Depends on|Dépend de)(?::\\*\\*|\\*\\*\\s*:)\\s*(.*)/.exec(corps); if (!m) return [];" > "$WORK/ancre-dep.txt"
node "$AUX/matrice.mjs" "$WORK/mut-anciennedep" "$WORK/p8mut" > "$WORK/mat-mut.json"
assert_eq "P8.3 — mutant (ancienne regex « Depends on » rétablie, ancre présente) : la matrice rougit sur les dépendances seules" "$(cat "$WORK/ancre-dep.txt")|$(G "$WORK/mat-mut.json" 'j.echecs>0&&j.echecs<=432&&j.traces.every(t=>t.startsWith("dep "))')" "muté|true"

# cas réel du portfolio (« **Depends on :** Phase 02 (…) ») et « Phase 01 » = « Phase 1 » pour les liens
L8="$WORK/p8-portfolio"; mkdir -p "$L8/.planning"
printf '%s\n' '# Roadmap' '' '- [x] **Phase 01: Fondations** - a' '- [x] **Phase 02: Contenu** - b' '- [ ] **Phase 03: Credibilite** - c' '' \
  '### Phase 01: Fondations' '**Goal :** corriger les findings' '' '### Phase 02: Contenu' '**Goal :** rendre le portfolio utilisable en mobile' '**Depends on :** Phase 1' '' \
  '### Phase 03: Credibilite' '**Goal :** éliminer les placeholders' '**Depends on :** Phase 02 (mobile UX fixes complète).' > "$L8/.planning/ROADMAP.md"
git -C "$L8" init -q; graph "$L8" "$WORK/g8.json"
assert_eq "P8.4 — portfolio : « **Depends on :** Phase 02 (…) » et « Phase 1 » donnent les liens 1>2 et 2>3 (clé de phase et cible concordent)" "$(G "$WORK/g8.json" 'j.links.filter(l=>l.k==="import").map(l=>l.a+">"+l.b).sort().join(",")')" "n:ph-1>n:ph-2,n:ph-2>n:ph-3"
assert_eq "P8.5 — portfolio : ids de phase normalisés ph-1, ph-2, ph-3 (01 = 1)" "$(G "$WORK/g8.json" 'j.nodes.filter(n=>n.kind==="phase").map(n=>n.id).sort().join(",")')" "ph-1,ph-2,ph-3"

# diagnostic : gabarit GSD riche = zéro ligne non comprise ; fixture illisible = lignes nommées fichier:ligne
L9="$WORK/p8-gsd"; B9="$L9/.planning"; mkdir -p "$B9"
printf '%s\n' '# Roadmap: Demo' '' '## Milestones' '' '- 🚧 **v1.0 MVP** - Phases 1-2 (en cours)' '' '## Phases' '' '- [ ] **Phase 1: Fondations** - socle' '- [ ] **Phase 1.1: Urgent (INSERTED)** - correctif' '- [ ] **Phase 2: Contenu** - pages' '' '## Phase Details' '' \
  '### Phase 1: Fondations' '**Goal**: Poser le socle. La Phase 2 en dépend.' '**Depends on**: Nothing' '**Requirements**: AUTH-01, AUTH-02' '**Success Criteria** (what must be TRUE):' '  1. Un utilisateur peut se connecter' '  2. Le build passe' '**Plans**: 2 plans' '' 'Plans:' '- [ ] 01-01-PLAN.md — socle' '- [ ] 01-02-PLAN.md — tests' '' \
  '### Phase 1.1: Urgent (INSERTED)' '**Goal**: Corriger' '**Depends on**: Phase 1' '' '### Phase 2: Contenu' '**Goal**: Pages' '**Depends on**: Phase 1 · **Parallélisable avec**: Phase 1.1' '' '## Progress' '' '| Phase | Plans Complete | Status | Completed |' '|-------|----------------|--------|-----------|' '| 1. Fondations | 0/2 | Not started | - |' > "$B9/ROADMAP.md"
printf '%s\n' '# Requirements' '' '## v1 Requirements' '' '- [ ] **AUTH-01**: Connexion' '- [x] **AUTH-02**: Déconnexion' '' '## v2 Requirements' '' '- [ ] **PERF-01**: Cache' '- [ ] Idée libre à trier 2 fois' '' '## Traceability' '' '| Requirement | Phase | Status |' '|---|---|---|' '| AUTH-01 | Phase 1 | Pending |' > "$B9/REQUIREMENTS.md"
printf -- '---\nstatus: executing\ncurrent_phase: 1\nmilestone: v1.0\n---\n\nPhase: 1 of 2\n' > "$B9/STATE.md"
git -C "$L9" init -q; graph "$L9" "$WORK/g9.json"
assert_eq "P8.6 — gabarit GSD riche (jalons, décimale, critères, plans, table, exigences) : zéro ligne non comprise (pas de faux positif)" "$(G "$WORK/g9.json" 'j.meta.vf.drift.nonComprisesN+"|"+j.meta.vf.drift.regles.filter(r=>r.regle==="ligne-non-comprise").length')" "0|0"
LA="$WORK/p8-illisible"; BA="$LA/.planning"; mkdir -p "$BA"
printf '%s\n' '# Roadmap' '' '## Phases' '- [ ] **Phase 1: Un** - a' '- [ ] **Phase 2 Deux** - b' '' '### Phase 1: Un' '**Goal**: g1' '**Depends on**: Nothing' '' '### Phase 2: Deux' '**Goal** — g2' 'Dépends sur : Phase 1' '' '##### Phase 3: Trois' 'Phase 3 est la plus grosse, voir Goal: aucun.' '' '```' '### Phase 9: dans un bloc de code' '- [ ] **Phase 8 Huit** - illisible hors du bloc' '```' > "$BA/ROADMAP.md"
printf '%s\n' '# R' '- [ ] **AUTH-01**: ok' '- [ ] **Req_02** illisible' '- [ ] Faire un truc 2 fois' > "$BA/REQUIREMENTS.md"
printf -- '---\nstatus: executing\ncurrent_phase: deux\n---\n' > "$BA/STATE.md"
git -C "$LA" init -q; graph "$LA" "$WORK/gA.json"
assert_eq "P8.7 — fixture illisible : 6 lignes non comprises, nommées fichier:ligne (prose, tableau et bloc de code jamais signalés)" "$(G "$WORK/gA.json" 'j.meta.vf.drift.nonComprisesN+"|"+j.meta.vf.drift.nonComprises.map(x=>x.fichier+":"+x.ligne).join(",")')" "6|.planning/ROADMAP.md:5,.planning/ROADMAP.md:12,.planning/ROADMAP.md:13,.planning/ROADMAP.md:15,.planning/REQUIREMENTS.md:3,.planning/STATE.md:3"
assert_eq "P8.8 — la règle ligne-non-comprise est dans les règles du panneau (niveau ignoré) et le résumé le dit" "$(G "$WORK/gA.json" 'j.meta.vf.drift.regles.filter(r=>r.regle==="ligne-non-comprise").map(r=>r.niveau+":"+r.n).join(",")+"|"+/6 ligne\(s\) non comprise\(s\)/.test(j.meta.vf.drift.resume)')" "ignoré:6|true"
DRA="$(node "$DR" "$LA")"
assert_eq "P8.9 — CLI du détecteur : une ligne par ligne non comprise avec fichier:ligne" "$(printf '%s\n' "$DRA" | grep -c '\[ignoré\] \.planning/ROADMAP\.md:12 ')" "1"
AVANT="$(find "$BA" -type f -exec cksum {} + | sort)"; node "$DR" "$LA" --json > "$WORK/dra.json"; node "$DR" "$LA" --diff > /dev/null
assert_eq "P8.10 — le détecteur n'écrit rien dans .planning (cksum avant/après) et ne propose aucun correctif (« apres ») pour une ligne non comprise" "$([ "$AVANT" = "$(find "$BA" -type f -exec cksum {} + | sort)" ] && echo identique)|$(G "$WORK/dra.json" '(l=>l.length===6&&l.every(c=>c.apres===undefined))(j.constats.filter(c=>c.regle==="ligne-non-comprise"))')" "identique|true"
mut7 sansdiag vf-cockpit-drift.mjs "for (const x of lignesNonComprises(txt, 'roadmap')) constats.push(nonComprise(fichier, x));" "" > "$WORK/ancre-diag.txt"
node "$AUX/q.mjs" "$WORK/mut-sansdiag" project "$LA" > "$WORK/gA-mut.json"
assert_eq "P8.11 — mutant (diagnostic du ROADMAP coupé, ancre présente) : le test P8.7 rougit (2 lignes du ROADMAP en moins : 2 restent, exigences et STATE)" "$(cat "$WORK/ancre-diag.txt")|$(G "$WORK/gA-mut.json" 'j.meta.vf.drift.nonComprisesN')" "muté|2"
assert_eq "P8.12 — l'interface porte le panneau (« Lignes non comprises », échappé par h, jeton --text-3, aucun px brut ajouté)" "$(grep -c 'const nonComprises = ' "$SCRIPTS/../skills/cockpit-moteur/assets/ui/00-vibeflow.js")|$(grep -c 'derive(V.drift)}${nonComprises(V.drift)}' "$SCRIPTS/../skills/cockpit-moteur/assets/ui/00-vibeflow.js")|$(grep -A3 'const nonComprises = ' "$SCRIPTS/../skills/cockpit-moteur/assets/ui/00-vibeflow.js" | grep -c 'px')" "1|1|0"

# ---------- P9 — corrections de la revue (cout linéaire, puces après une ligne vide, CRLF, « Depends on Phase 3 », mot-clé collé, cases à tiret) ----------
echo "=== P9 — corrections de la revue du parseur tolérant ==="
cat > "$AUX/lin.mjs" <<'JS'
// lin.mjs <scripts> : 100 000 espaces dans six formes de ligne ; readPlanning ET detectDrift doivent rester sous 1 s chacun (quadratique : plusieurs secondes). « ok » ou les formes lentes.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts] = process.argv; const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
const { readPlanning } = await imp('vf-cockpit-planning.mjs'); const { detectDrift } = await imp('vf-cockpit-drift.mjs');
const N = ' '.repeat(100000), lentes = [];
const FORMES = { titre: '##' + N, case: '- [ ]' + N, 'case-gras': '- [ ] **' + N, dep: '### Phase 1: A\n**Depends on:** Phase 2' + N + 'x', 'dep-gras': '### Phase 1: A\n**' + N + 'Depends on:** 2', 'nom-case': '- [ ] **Phase 1: A' + N + 'x** - d', 'nom-suffixe': '- [x] Phase 1: A' + N + '(complete', 'dep-point': '### Phase 1: A\n**Depends on:** 2' + N + ' · x', nu: '### Phase 1: A\n' + N + 'Depends on' + N + '9' };
for (const [nom, l] of Object.entries(FORMES)) {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), 'lin-')); fs.mkdirSync(path.join(d, '.planning')); fs.writeFileSync(path.join(d, '.planning/ROADMAP.md'), '# R\n\n' + l + '\n');
  const a = Date.now(); readPlanning(d, undefined, { sansTags: true }); const b = Date.now(); detectDrift(d); const c = Date.now();
  if (b - a > 1000) lentes.push(`${nom} lecture ${b - a} ms`); if (c - b > 1000) lentes.push(`${nom} diagnostic ${c - b} ms`);
  fs.rmSync(d, { recursive: true, force: true });
}
console.log(lentes.length ? lentes.join(' ; ') : 'ok');
JS
assert_eq "P9.1 (C1) — coût linéaire : 100 000 espaces dans six formes de ligne, lecture et diagnostic sous 1 s chacun" "$(node "$AUX/lin.mjs" "$SCRIPTS")" "ok"
cat > "$AUX/c.mjs" <<'JS'
// c.mjs <scripts> <cas> : sondes unitaires de P9 sur une planification jetable ; une ligne de sortie
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, cas] = process.argv; const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
const { readPlanning } = await imp('vf-cockpit-planning.mjs'); const { detectDrift } = await imp('vf-cockpit-drift.mjs'); const { buildProjectGraph } = await imp('vf-cockpit-project.mjs');
const mk = (road, state) => { const d = fs.mkdtempSync(path.join(os.tmpdir(), 'c-')); fs.mkdirSync(path.join(d, '.planning')); fs.writeFileSync(path.join(d, '.planning/ROADMAP.md'), road); if (state) fs.writeFileSync(path.join(d, '.planning/STATE.md'), state); return d; };
const deps = (road) => [...readPlanning(mk(road), undefined, { sansTags: true }).phases.values()].map((p) => `${p.n}:${p.depends}`).join(' ');
const nc = (road) => detectDrift(mk(road)).constats.filter((c) => c.regle === 'ligne-non-comprise').map((c) => c.ligne).join(',');
if (cas === 'puces') { const f = (sep) => deps(`### Phase 1: A\n### Phase 2: B\n**Depends on:**${sep}- Phase 1\n- Phase 1\n`); console.log([f('\n'), f('\n\n'), f('\n \n\n')].join('|')); }
else if (cas === 'crlf') { const f = (nl, bom) => (detectDrift(mk('- [ ] **Phase 1: A** - x\n### Phase 1: A\n', `${bom}---${nl}milestone: v9.9${nl}status: executing${nl}current_phase: 1${nl}---${nl}`)).constats.find((c) => c.regle === 'jalons-absents')?.apres.match(/\*\*([^*]+)\*\*/)?.[1]); console.log([f('\n', ''), f('\r\n', ''), f('\r\n', '﻿')].join('|')); }
else if (cas === 'dep-sans-deux-points') console.log(nc('### Phase 1: A\nDepends on Phase 3\n- Depends on Phase 3\n**Depends on** Phase 3\n**Depends on**: Phase 3\nLa Phase 2 en dépend.\nDependencies are documented below.\n'));
else if (cas === 'case-vide') console.log([deps('- [ ] Phase 1:\n- [ ] Phase 2: B\n'), deps('- [ ] Phase 1 —\n- [ ] Phase 2 — B\n')].map(() => '').join('') + [...readPlanning(mk('- [ ] Phase 1:\n- [ ] Phase 2: B\n'), undefined, { sansTags: true }).phases.values()].map((p) => `${p.n}=${p.name}`).join(',') + '|' + [...readPlanning(mk('- [x] Phase 1 —\n- [ ] Phase 2 — B\n'), undefined, { sansTags: true }).phases.values()].map((p) => `${p.n}=${p.name}${p.done ? '+' : ''}`).join(','));
else if (cas === 'backlog-crlf') { const f = (nl) => { const d = mk('- [ ] **Phase 1: A** - x\n### Phase 1: A\n'); fs.writeFileSync(path.join(d, '.planning/BACKLOG.md'), ['## Un — INVESTIGUÉ', 'texte un', '## Deux', 'texte deux', ''].join(nl)); return buildProjectGraph(d).files.filter((x) => x.p.startsWith('.planning/BACKLOG.md#')).length; }; console.log(f('\n') + '|' + f('\r\n')); }
else if (cas === 'colle') console.log(nc("### Phase 1: A\n- goal-backward : valider d'abord\nObjectif-cible : x\nGoal-driven : y\n**Goal** — non lu\n"));
JS
assert_eq "P9.2 (C2) — puces après un en-tête vide : lues pareil avec 0, 1 ou 2 lignes vides intercalées" "$(node "$AUX/c.mjs" "$SCRIPTS" puces)" "1: 2:1|1: 2:1|1: 2:1"
assert_eq "P9.3 (C4) — jalons-absents propose le jalon du STATE (v9.9) en LF, en CRLF et en CRLF avec BOM" "$(node "$AUX/c.mjs" "$SCRIPTS" crlf)" "v9.9|v9.9|v9.9"
assert_eq "P9.4 (C5) — « Depends on Phase 3 » sans deux-points (nu, puce, gras) est SIGNALÉE (lignes 2,3,4), pas lue ; la forme correcte, la prose « en dépend » et « Dependencies are documented » ne le sont pas" "$(node "$AUX/c.mjs" "$SCRIPTS" dep-sans-deux-points)" "2,3,4"
assert_eq "P9.10 (R4) — un nom de case vide reste vide : « Phase 1: » puis « Phase 2: B » donnent deux phases, avec deux-points ET avec tiret (la ligne suivante est lue pour elle-même)" "$(node "$AUX/c.mjs" "$SCRIPTS" case-vide)" "1=,2=B|1=+,2=B"
assert_eq "P9.11 (R5) — BACKLOG.md en CRLF : même nombre d'entrées qu'en LF (2)" "$(node "$AUX/c.mjs" "$SCRIPTS" backlog-crlf)" "2|2"
assert_eq "P9.5 (C6) — mot-clé collé à un trait d'union (goal-backward, Objectif-cible, Goal-driven) : jamais signalé ; « **Goal** — » l'est toujours" "$(node "$AUX/c.mjs" "$SCRIPTS" colle)" "5"
mut7 fence vf-cockpit-formats.mjs "    if (code) return;
" "" > "$WORK/ancre-fence.txt"
node "$AUX/q.mjs" "$WORK/mut-fence" project "$LA" > "$WORK/gA-fence.json"
assert_eq "P9.6 (C3) — mutant (gestion des blocs de code retirée) : la ligne illisible DANS le bloc est signalée, P8.7 rougirait (7 au lieu de 6)" "$(cat "$WORK/ancre-fence.txt")|$(G "$WORK/gA-fence.json" 'j.meta.vf.drift.nonComprisesN')" "muté|7"
printf -- '- [ ] Phase 1 sans séparateur\n' | wr "$WORK/p9-ill/.planning/ROADMAP.md"
mut7 sansillisible vf-cockpit-drift.mjs "if (!nb && /(^|\\n)" "if (false && /(^|\\n)" > "$WORK/ancre-illis.txt"
assert_eq "P9.7 (C10) — P6.9 garde son sens : sur « Phase 1 sans séparateur » le détecteur dit bloquant ; mutant (règle phases-illisibles coupée) : plus rien" "$(cat "$WORK/ancre-illis.txt")|$(node "$DR" "$WORK/p9-ill" --json | G /dev/stdin 'j.constats.filter(c=>c.niveau==="bloquant").length')|$(node "$WORK/mut-sansillisible/vf-cockpit-drift.mjs" "$WORK/p9-ill" --json | G /dev/stdin 'j.constats.filter(c=>c.niveau==="bloquant").length')" "muté|1|0"
UIP="$SCRIPTS/../skills/cockpit-moteur/assets/ui/00-vibeflow.js"
assert_eq "P9.8 (C7) — le chemin fichier:ligne du panneau ne se coupe jamais (white-space:nowrap, word-break:normal sur le <code> de nonComprises, aucun px)" "$(grep -A3 'const nonComprises = ' "$UIP" | grep -c '<code style="white-space:nowrap;word-break:normal">')|$(grep -A3 'const nonComprises = ' "$UIP" | grep -c 'px')" "1|0"
assert_eq "P9.9 (C8) — le commentaire de avancement.mjs dit où vit normNum (formats, ré-exporté par planning)" "$(grep -c 'normNum de vf-cockpit-formats, ré-exporté par vf-cockpit-planning' "$SCRIPTS/vf-cockpit-avancement.mjs")" "1"

# ---------- P10 — croissance : aucune regex lue sur le planning n'est plus que linéaire (classe fermée, pas une forme à la fois) ----------
# Inventaire des regex appliquées au texte du planning (formats.mjs : tous les motifs de champ, de titre, d'exigence, de coupe et du diagnostic ; planning.mjs : nom de case, suffixe de statut,
# jalons, frontmatter ; drift.mjs : espace avant « : », coupe « · », phases illisibles, jalons ; project.mjs : objectif de plan, intertitres de BACKLOG ; avancement.mjs : statut de recette).
# Le test fabrique pour chaque forme lue et chaque caractère pathologique une ligne à N puis 2N, lue par readPlanning ET detectDrift ; il juge le RAPPORT des temps, pas un temps absolu seul.
cat > "$AUX/croissance.mjs" <<'JS'
// croissance.mjs <scripts> [bavard] : test de CROISSANCE générique. Pour chaque forme de ligne que le cockpit lit dans .planning/ (titres, cases, dépendances, Goal, exigences, jalons,
// STATE, puces) et chaque caractère de chaque classe (espaces des 4 sortes, * _ ( ) [ ] - — – # : : chiffres), une ligne pathologique est fabriquée (trous « ◇ » remplis de N caractères,
// avec et sans saut de ligne final) puis lue à N et 2N par readPlanning ET detectDrift. Échec : le temps à 2N dépasse 2,8 fois celui à N (tailles où il dépasse le bruit) ou 1,5 s.
// Sortie : « ok <nb de cas> » ou les premiers échecs « forme | caractère | opération | N → 2N | t1 → t2 | ratio ».
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, bavard] = process.argv; const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
const { readPlanning } = await imp('vf-cockpit-planning.mjs'); const { detectDrift } = await imp('vf-cockpit-drift.mjs'); const { buildProjectGraph } = await imp('vf-cockpit-project.mjs');
const N = 20000, SEUIL = 2.8, BRUIT = 40, PLAFOND = 1500;
const CARS = [' ', '\t', ' ', ' ', '*', '_', '(', ')', '[', ']', '-', '—', '–', '#', ':', '1', '.', '·', '\n', '\u2028', '\u2029'];
// formes : { f: ligne avec trous ◇, doc: 'roadmap' | 'exigences' | 'state' | 'jalons' }
const FORMES = [
  ['##◇', 'roadmap'], ['## ◇Phase 1◇', 'roadmap'], ['## Phase 1◇:◇x', 'roadmap'], ['### Phase 1 ◇—◇x', 'roadmap'], ['#### **◇Phase 1: x**◇', 'roadmap'], ['## Phase ◇1 — ◇', 'roadmap'], ['## Phase 1 ◇—', 'roadmap'],
  ['- [ ]◇', 'roadmap'], ['- [x] **◇Phase 1: x◇**◇- ◇d', 'roadmap'], ['- [ ] Phase 1: A◇(complete◇', 'roadmap'], ['- [X] Phase 1 ◇- ◇Trois', 'roadmap'], ['* [ ] **Phase ◇1◇**', 'roadmap'],
  ['### Phase 1: A\n**Depends on:**◇', 'roadmap'], ['### Phase 1: A\n**Depends on:** 1 **◇x', 'roadmap'], ['### Phase 1: A\n**Depends on:** (◇', 'roadmap'], ['### Phase 1: A\n**Depends on:** 2 ◇· ◇x', 'roadmap'],
  ['### Phase 1: A\nDepends on◇:◇1◇', 'roadmap'], ['### Phase 1: A\n- ◇Depends on ◇Phase 2', 'roadmap'], ['### Phase 1: A\n**◇Depends on◇**◇:◇ 2', 'roadmap'], ['### Phase 1: A\n**Depends on:**\n◇- ◇Phase 1', 'roadmap'],
  ['### Phase 1: A\n**Depends on:** 3. ◇A', 'roadmap'], ['### Phase 1: A\n**Depends on:** P1-D-◇1', 'roadmap'],
  ['### Phase 1: A\n**Goal**:◇\n**x', 'roadmap'], ['### Phase 1: A\nGoal ◇: ◇y', 'roadmap'], ['### Phase 1: A\n**Goal** ◇— ◇z', 'roadmap'], ['### Phase 1: A\n**Goal**: a\n◇\n◇\n**Depends on**: 1', 'roadmap'],
  ['- [ ] **◇REQ-1◇**:◇x', 'exigences'], ['- [ ] ◇A-◇1', 'exigences'], ['- [x] **A-1:**◇y', 'exigences'], ['| ◇AB-1◇ | Phase ◇2 |', 'exigences'],
  ['## Milestones\n\n- ✅ **v1** — Phases 1-◇', 'jalons'], ['## Milestones\n\n- ✅ **v1** — Phases ◇-◇', 'jalons'], ['## Milestones\n\n- ✅ **◇v1◇** — ◇Phases ◇1', 'jalons'],
  ['## T◇— x', 'backlog'], ['## T ◇— ◇x', 'backlog'], ['## ◇T — ◇', 'backlog'], ['<objective>◇', 'plan'], ['<objective>◇</objective>', 'plan'], ['※', 'plan'], ['---\ndepends_on: ◇\n', 'plan'], ['---\nfiles_modified: [◇\n', 'plan'],
  ['current_phase: ◇', 'state'], ['status: ◇', 'state'], ['current_phase: "◇2"', 'state'],
];
const holes = (f, c) => f.split('◇').join(c.repeat(N));
const t = (g) => { const a = process.hrtime.bigint(); g(); return Number(process.hrtime.bigint() - a) / 1e6; };
const mesure = (ops, ecrire, taille) => { const d = fs.mkdtempSync(path.join(os.tmpdir(), 'cr-')); fs.mkdirSync(path.join(d, '.planning')); ecrire(d, taille); const r = Object.fromEntries(ops.map(([nom, g]) => [nom, Math.min(t(() => g(d)), t(() => g(d)))])); fs.rmSync(d, { recursive: true, force: true }); return r; };
const OPS = [['readPlanning', (d) => readPlanning(d, undefined, { sansTags: true })], ['detectDrift', (d) => detectDrift(d)]];
const OPS_PROJET = [['buildProjectGraph', (d) => buildProjectGraph(d)]]; // BACKLOG, plans : lus par le graphe Projet seulement
const echecs = []; let cas = 0; const FILTRE = process.env.CROISSANCE_FORME || ''; // sous-chaîne : restreint aux formes qui la contiennent (preuves par mutant)
for (const [forme, doc] of FORMES.filter(([f]) => f.includes(FILTRE))) for (const c of CARS) for (const [queue, fin] of [['', '\n'], ['', ''], ['v\u2028w', '\n']]) {
  if (forme.includes('※') && c !== CARS[0]) continue; // forme à jeton : une seule passe
  const ops = doc === 'backlog' || doc === 'plan' ? OPS_PROJET : OPS;
  const f = (taille) => forme.split('◇').join(c.repeat(taille)).split('※').join('<objective>'.repeat(Math.floor(taille / 2)));
  const ecrire = (d, taille) => {
    const p = (x) => path.join(d, '.planning', x); const ligne = f(taille) + queue + fin;
    if (doc === 'exigences') fs.writeFileSync(p('REQUIREMENTS.md'), ligne);
    else if (doc === 'state') { fs.writeFileSync(p('ROADMAP.md'), '### Phase 1: A\n'); fs.writeFileSync(p('STATE.md'), '---\n' + ligne + (fin ? '---\n' : '')); }
    else if (doc === 'backlog' || doc === 'plan') {
      fs.writeFileSync(p('ROADMAP.md'), '- [ ] **Phase 1: A** - x\n### Phase 1: A\n');
      if (doc === 'backlog') fs.writeFileSync(p('BACKLOG.md'), ligne); else { fs.mkdirSync(p('phases/01-a'), { recursive: true }); fs.writeFileSync(p('phases/01-a/01-01-PLAN.md'), ligne); }
    }
    else fs.writeFileSync(p('ROADMAP.md'), (doc === 'jalons' ? '- [ ] **Phase 1: A**\n\n' : '') + ligne);
  };
  cas++;
  let a = mesure(ops, ecrire, N), b = mesure(ops, ecrire, 2 * N);
  for (const [nom] of ops) {
    let r = b[nom] / Math.max(a[nom], 1);
    for (let k = 0; k < 2 && b[nom] > BRUIT && (r > SEUIL || b[nom] > PLAFOND); k++) { a = mesure(ops, ecrire, N); b = mesure(ops, ecrire, 2 * N); r = b[nom] / Math.max(a[nom], 1); } // un faux rouge de bruit ne survit pas à deux rejeux
    if (b[nom] > BRUIT && (r > SEUIL || b[nom] > PLAFOND)) echecs.push(`${JSON.stringify(forme)} | ${JSON.stringify(c)}${fin ? '' : ' sans \\n final'}${queue ? ' + queue ' + JSON.stringify(queue) : ''} | ${nom} | ${N} → ${2 * N} | ${a[nom].toFixed(0)} ms → ${b[nom].toFixed(0)} ms | ×${r.toFixed(1)}`);
  }
}
console.log(echecs.length ? `${echecs.length} échec(s) sur ${cas} cas :\n` + echecs.slice(0, Number(bavard) || 12).join('\n') : `ok ${cas}`);
JS
CR="$(node "$AUX/croissance.mjs" "$SCRIPTS")"
assert_eq "P10.1 — croissance : 2712 cas (44 formes x 21 caractères dont U+2028/U+2029 x 3 fins de ligne), lecture, diagnostic et graphe Projet (BACKLOG, plans), ratio 2N/N sous 2,8" "$CR" "ok 2712"
mut7 cr-paren vf-cockpit-formats.mjs ".replace(PARENTHESES, ' ')" ".replace(/\\([^)]*\\)/g, ' ')" > "$WORK/ancre-cr1.txt"
mut7 cr-coupe vf-cockpit-formats.mjs "(?::\\\\*\\\\*|\\\\*\\\\*\${COLON})))" "(?:\${COLON}\\\\*\\\\*|\\\\*\\\\*\${COLON})))" > "$WORK/ancre-cr2.txt"
mut7 cr-backlog vf-cockpit-project.mjs "(?<!\\s)\\s+—\\s+" "\\s+—\\s+" > "$WORK/ancre-cr3.txt"
mut7 cr-objectif vf-cockpit-project.mjs "objectif(txt) ||" "/<objective>\\s*([\\s\\S]*?)<\\/objective>/.exec(txt)?.[1] ||" > "$WORK/ancre-cr4.txt"
assert_eq "P10.4 (R2) — mutant (ancienne coupe de l'intertitre de BACKLOG rétablie) : le test de croissance rougit, par buildProjectGraph" "$(cat "$WORK/ancre-cr3.txt")|$(CROISSANCE_FORME='## T◇— x' node "$AUX/croissance.mjs" "$WORK/mut-cr-backlog" | grep -c 'échec(s) sur')" "muté|1"
assert_eq "P10.5 (R2) — mutant (ancienne regex de <objective> rétablie) : le test de croissance rougit, par buildProjectGraph" "$(cat "$WORK/ancre-cr4.txt")|$(CROISSANCE_FORME='※' node "$AUX/croissance.mjs" "$WORK/mut-cr-objectif" | grep -c 'échec(s) sur')" "muté|1"
assert_eq "P10.2 — mutant (ancienne regex des parenthèses rétablie, ancre présente) : le test de croissance rougit" "$(cat "$WORK/ancre-cr1.txt")|$(CROISSANCE_FORME='Depends on:** (' node "$AUX/croissance.mjs" "$WORK/mut-cr-paren" | grep -c 'échec(s) sur')" "muté|1"
assert_eq "P10.3 — mutant (ancienne coupe de valeur rétablie, ancre présente) : le test de croissance rougit" "$(cat "$WORK/ancre-cr2.txt")|$(CROISSANCE_FORME='Depends on:** 1 **' node "$AUX/croissance.mjs" "$WORK/mut-cr-coupe" | grep -c 'échec(s) sur')" "muté|1"

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then
  echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"
  exit 1
fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
