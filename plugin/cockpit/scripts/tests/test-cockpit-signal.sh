#!/usr/bin/env bash
# test-cockpit-signal.sh — émetteur signal@1 : chaîne réelle node + émetteur, contrat, sérialisation sans recalcul, sans réseau
# (VFSG-03, VFSG-11 ; P68-D-02, P68-D-14, P68-D-15)
#   S0 contrôles positifs des fixtures (lab, deux worktrees, disposition de plugin à conductor voisin factice)
#   S1 chaîne réelle : `node vf-cockpit-signal.mjs <lab>` en sous-processus, schéma signal@1
#   S2 sortie conforme au contrat versionné (clés requises, types, aucun interdit à toute profondeur, equipe = who@2)
#   S3 contenu : avancement@2, mission abandonnée, jalons, archive exclue, worktrees, retard, phase active
#   S4 sérialisation sans recalcul : avancement et état de mission égaux à ceux de readPlanning
#   S5 aucun réseau : sonde node à 0 connexion, emballage git sans sous-commande réseau (témoins positifs)
#   S6 résolution du verrou (P68-D-28) : conductor voisin, repli absent, source illisible, script planté dans le lab jamais exécuté
#   S7 bornes : nom de worktree piégé, étape de nœud de 500 caractères, usage invalide, `--plugin-root` refusée
#   S8 copies mutées (état de mission recalculé, avancement recalculé) : détectées
# Fixtures construites dans mktemp, jamais de dépôt distant. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t.test GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t.test
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
unset VF_COCKPIT_SCRIPTS_DIR   # la disposition de chaque lancement décide seule du dossier de scripts (P68-D-29)

WORK="$(mktemp -d)"
trap 'vf_hyg_fin; rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/bin" "$WORK/home" "$WORK/home-vide"
GIT_REEL="$(command -v git)"
export HOME="$WORK/home"

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

# --- outils node écrits par la suite ---
cat > "$AUX/get.mjs" <<'JS'
import fs from 'node:fs';
let j; try { j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')); } catch { console.log('illisible'); process.exit(0); }
let v; try { v = new Function('j', 'return (' + process.argv[3] + ')')(j); } catch { v = 'illisible'; }
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
# q.mjs <scripts> <lab> <dossier de scripts du verrou> : readPlanning -> avancement par phase et état par DAG (ce que l'émetteur doit seulement sérialiser)
cat > "$AUX/q.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, root, sd] = process.argv;
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-planning.mjs')).href);
const P = m.readPlanning(root, undefined, { scriptsDir: sd });
console.log(JSON.stringify({ phases: [...P.phases.values()].map((p) => ({ key: p.key, avancement: p.avancement })), dags: P.dags.map((d) => ({ name: d.name, etat: d.etat })) }));
JS
# cmp.mjs <avancement|etat> <signal.json> <q.json> : OK, ou KO <détail>, ou illisible
cat > "$AUX/cmp.mjs" <<'JS'
import fs from 'node:fs';
const [, , what, sf, qf] = process.argv;
let s, q; try { s = JSON.parse(fs.readFileSync(sf, 'utf8')); q = JSON.parse(fs.readFileSync(qf, 'utf8')); } catch { console.log('illisible'); process.exit(0); }
const errs = [];
if (what === 'avancement') {
  const ref = new Map(q.phases.map((p) => [p.key, JSON.stringify(p.avancement)]));
  if (!Array.isArray(s.phases) || !s.phases.length) errs.push('aucune phase émise');
  for (const p of s.phases || []) if (JSON.stringify(p.avancement) !== ref.get(p.key)) errs.push(`phase ${p.key}`);
} else {
  const ref = new Map(q.dags.map((d) => [d.name, d.etat]));
  if (!Array.isArray(s.missions) || !s.missions.length) errs.push('aucune mission émise');
  for (const m of s.missions || []) if (m.etat !== ref.get(m.nom)) errs.push(`mission ${m.nom} : ${m.etat} au lieu de ${ref.get(m.nom)}`);
}
console.log(errs.length ? 'KO ' + errs.join(' | ') : 'OK');
JS
# validate.mjs <interface.json> <schemaId> <sortie.json> — clés requises et typées, clés interdites à toute profondeur, sous-objets au contrat
cat > "$AUX/validate.mjs" <<'JS'
import fs from 'node:fs';
const [, , ifaceF, id, outF] = process.argv;
let spec, out;
try { spec = JSON.parse(fs.readFileSync(ifaceF, 'utf8')).schemas[id]; } catch { spec = null; }
if (!spec) { console.log('KO schéma absent du contrat : ' + id); process.exit(1); }
try { out = JSON.parse(fs.readFileSync(outF, 'utf8')); } catch { console.log('KO sortie illisible'); process.exit(1); }
const errs = [];
const type = (v) => (Array.isArray(v) ? 'array' : v === null ? 'null' : typeof v);
for (const [k, t] of Object.entries(spec.requis || {})) {
  if (!(k in out)) errs.push(`clé requise absente : ${k}`);
  else if (t !== 'any' && type(out[k]) !== t) errs.push(`type de ${k} : ${type(out[k])} au lieu de ${t}`);
}
if (out.schema !== id && id.includes('signal')) errs.push(`schema = ${out.schema}`);
const deep = (o, f) => { if (o && typeof o === 'object') for (const [k, v] of Object.entries(o)) { f(k); deep(v, f); } };
deep(out, (k) => { if ((spec.interdits || []).includes(k)) errs.push(`clé interdite présente : ${k}`); });
const sous = (objs, nom) => { // chaque élément porte ses clés requises et rien hors requis + optionnels
  const s = spec[nom]; if (!s) { errs.push(`sous-schéma absent du contrat : ${nom}`); return; }
  for (const o of objs) {
    for (const k of s.requis || []) if (!(k in o)) errs.push(`${nom} : clé ${k} absente`);
    for (const k of Object.keys(o)) if (!(s.requis || []).includes(k) && !(s.optionnels || []).includes(k)) errs.push(`${nom} : clé ${k} hors contrat`);
  }
};
if (id.includes('signal')) {
  sous(out.phases || [], 'phase'); sous(out.jalons || [], 'jalon'); sous(out.missions || [], 'mission');
  sous((out.missions || []).flatMap((m) => m.noeuds || []), 'noeud'); sous((out.verrous?.liste) || [], 'verrou');
  sous(out.arbres || [], 'arbre'); sous((out.arbres || []).map((a) => a.retard).filter(Boolean), 'retard');
}
console.log(errs.length ? 'KO ' + errs.join(' | ') : 'OK');
process.exit(errs.length ? 1 : 0);
JS
cat > "$AUX/mutsub.mjs" <<'JS'
// mutsub.mjs <fichier> — remplace UNE occurrence exacte de $FROM par $TO dans une COPIE ; "ancre absente" si $FROM n'y est pas
import fs from 'node:fs';
const f = process.argv[2];
let t; try { t = fs.readFileSync(f, 'utf8'); } catch { console.log('ancre absente'); process.exit(1); }
if (!t.includes(process.env.FROM)) { console.log('ancre absente'); process.exit(1); }
fs.writeFileSync(f, t.replace(process.env.FROM, () => process.env.TO)); console.log('muté');
JS
cat > "$AUX/sonde.mjs" <<'JS'
import net from 'node:net';
import tls from 'node:tls';
import dns from 'node:dns';
import http from 'node:http';
import https from 'node:https';
import fs from 'node:fs';
const out = process.env.VF_SONDE_OUT;
fs.appendFileSync(out + '.charge', 'sonde chargée\n');
const rec = (genre, cible) => { fs.appendFileSync(out, `${genre} ${String(cible ?? '')}\n`); };
const refus = (genre) => (...a) => { rec(genre, typeof a[0] === 'object' ? JSON.stringify(a[0]) : a[0]); throw new Error('sonde : ' + genre); };
net.connect = refus('net'); net.createConnection = refus('net'); tls.connect = refus('tls');
net.Socket.prototype.connect = function (...a) { rec('net', typeof a[0] === 'object' ? JSON.stringify(a[0]) : a[0]); throw new Error('sonde : socket'); };
dns.lookup = refus('dns'); if (dns.promises) dns.promises.lookup = async (...a) => { rec('dns', a[0]); throw new Error('sonde : dns'); };
http.request = refus('http'); http.get = refus('http'); https.request = refus('https'); https.get = refus('https');
globalThis.fetch = (u) => { rec('fetch', typeof u === 'string' ? u : u?.url ?? String(u)); return Promise.reject(new Error('sonde : fetch')); };
JS
cat > "$AUX/temoin-sortant.mjs" <<'JS'
fetch('https://exemple.test/').catch(() => {});
import('node:net').then((m) => { try { (m.default || m).connect(443, 'exemple.test'); } catch {} });
setTimeout(() => process.exit(0), 300);
JS
G() { node "$AUX/get.mjs" "$@"; }
IFACE="$SCRIPTS/vf-cockpit-interface.json"
# emballage git : journalise l'argv puis exécute le vrai git
cat > "$WORK/bin/git" <<EOS
#!/bin/sh
printf '%s\n' "\$*" >> "$WORK/git.log"
exec "$GIT_REEL" "\$@"
EOS
chmod +x "$WORK/bin/git"
G_() { "$GIT_REEL" "$@"; }

# --- dispositions de plugin : le fichier du dépôt est COPIÉ dans <disp>/cockpit/scripts ; <disp>/conductor/scripts/driver-lock.sh est le faux voisin ---
# mkdisp <disp> <vrai|texte|aucun> : conductor voisin qui répond {"present": false} (journalisé), du texte non JSON, ou absent
mkdisp() {
  rm -rf "$1"; mkdir -p "$1/cockpit/scripts"
  cp "$SCRIPTS"/*.mjs "$SCRIPTS"/*.json "$1/cockpit/scripts/"
  case "$2" in
    vrai) mkdir -p "$1/conductor/scripts"
      printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s"\ncase "$1" in status) echo "{\\"present\\": false}";; orphans) echo "{\\"orphans\\":[]}";; esac\n' "$WORK/dl.log" > "$1/conductor/scripts/driver-lock.sh" ;;
    texte) mkdir -p "$1/conductor/scripts"
      printf '#!/usr/bin/env bash\necho "ceci n est pas du json"\n' > "$1/conductor/scripts/driver-lock.sh" ;;
  esac
  [ -f "$1/conductor/scripts/driver-lock.sh" ] && chmod +x "$1/conductor/scripts/driver-lock.sh"
  return 0
}
FP="$WORK/plugin"; mkdisp "$FP" vrai
# RUN <disposition> <HOME> <sortie> <args...> : la chaîne réelle, en sous-processus ; rend le code de sortie
RUN() { local d="$1" h="$2" o="$3"; shift 3; HOME="$h" node "$d/cockpit/scripts/vf-cockpit-signal.mjs" "$@" > "$o" 2> "$o.err"; echo $?; }

# --- fixtures : lab plat git à deux worktrees (l'un en retard de 3 commits), DAG MISSION-1 à nœud running, archive de jalon ---
L="$WORK/lab"; W="$WORK/wt-2"
G_ init -q -b main "$L"
mkdir -p "$L/.planning/missions" "$L/.planning/milestones"
printf -- '# Roadmap\n\n## Milestones\n\n- 🚧 **v1.0 Test** - Phases 1-2\n\n## Phases\n\n- [ ] **Phase 1: Un** - a\n- [ ] **Phase 2: Deux** - b\n' > "$L/.planning/ROADMAP.md"
printf -- '- [x] **Phase 9: Ancienne** - z\n' > "$L/.planning/milestones/v0-ROADMAP.md"
LONG="$(printf 'x%.0s' $(seq 1 500))"
printf '{"nodes":[{"id":"a","step":"%s","stage":"exec","deps":[],"status":"running"}]}\n' "$LONG" > "$L/.planning/missions/MISSION-1.dag.json"
G_ -C "$L" add -A; G_ -C "$L" commit -q -m c0
G_ -C "$L" branch feat/phase-2-x
G_ -C "$L" worktree add -q "$W" feat/phase-2-x 2>/dev/null
for i in 1 2 3; do G_ -C "$L" commit -q --allow-empty -m "m$i"; done

echo "=== S0 — contrôles positifs des fixtures ==="
assert_eq "S0.1 — fixture : l'arbre W est en retard de 3 commits sur main (git réel)" "$(G_ -C "$W" rev-list --count HEAD..main)" "3"
assert_eq "S0.2 — fixture : git worktree list voit deux arbres" "$(G_ -C "$L" worktree list --porcelain | grep -c '^worktree ')" "2"
assert_eq "S0.3 — fixture : le DAG MISSION-1 porte un nœud running de 500 caractères" "$(G "$L/.planning/missions/MISSION-1.dag.json" 'j.nodes[0].status+"|"+j.nodes[0].step.length')" "running|500"
assert_eq "S0.4 — disposition : le conductor voisin factice répond present:false" "$(bash "$FP/conductor/scripts/driver-lock.sh" status --all)" '{"present": false}'
: > "$WORK/dl.log"

echo "=== S1 — la chaîne réelle node + émetteur ==="
RC1="$(RUN "$FP" "$HOME" "$WORK/o1.json" "$L")"
assert_eq "S1.1 — chaîne réelle node + émetteur : schéma signal@1" "$(G "$WORK/o1.json" 'j.schema')" "vibeflow/cockpit-signal@1"
assert_eq "S1.2 — le sous-processus sort 0 et une seule ligne de JSON" "$RC1|$(grep -c . "$WORK/o1.json")" "0|1"

echo "=== S2 — conformité au contrat versionné ==="
assert_eq "S2.1 — sortie conforme au contrat signal@1" "$(node "$AUX/validate.mjs" "$IFACE" vibeflow/cockpit-signal@1 "$WORK/o1.json")" "OK"
G "$WORK/o1.json" 'j.equipe' > "$WORK/o1-equipe.json"
assert_eq "S2.2 — equipe valide cockpit-who@2" "$(node "$AUX/validate.mjs" "$IFACE" vibeflow/cockpit-who@2 "$WORK/o1-equipe.json")" "OK"
node -e 'const fs=require("fs");const j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));j.missions[0].vie={doing:"x"};fs.writeFileSync(process.argv[2],JSON.stringify(j))' "$WORK/o1.json" "$WORK/o1-doing.json" 2>/dev/null
assert_has "S2.3 — témoin : un champ doing glissé en profondeur est refusé" "$(node "$AUX/validate.mjs" "$IFACE" vibeflow/cockpit-signal@1 "$WORK/o1-doing.json")" "clé interdite présente : doing"
assert_eq "S2.4 — le contrat déclare schema dans requis et les quatre interdits" "$(G "$IFACE" 'j.schemas["vibeflow/cockpit-signal@1"]?.requis?.schema+"|"+(j.schemas["vibeflow/cockpit-signal@1"]?.interdits||[]).join()')" "string|doing,mandat,messages,outils"

echo "=== S3 — contenu ==="
S="$WORK/o1.json"
assert_eq "S3.1 — phases[0].avancement.version = 2 ; phases d'archive exclues (1 et 2 seulement)" "$(G "$S" 'j.phases[0].avancement.version+"|"+j.phases.map(p=>p.n).join()')" "2|1,2"
assert_eq "S3.2 — mission sans verrou : abandonnee" "$(G "$S" 'j.missions.find(m=>m.nom==="MISSION-1").etat')" "abandonnee"
assert_eq "S3.3 — libellé de la mission abandonnée" "$(G "$S" 'j.missions.find(m=>m.nom==="MISSION-1").libelle')" "abandonnée, nœuds non refermés"
assert_eq "S3.4 — deux arbres, retard.main = 3 sur l'arbre feat/phase-2-x" "$(G "$S" 'j.arbres.length+"|"+j.arbres.find(a=>a.branche==="feat/phase-2-x").retard.main')" "2|3"
assert_eq "S3.5 — phaseActive de l'arbre feat/phase-2-x = la phase 2" "$(G "$S" 'j.arbres.find(a=>a.branche==="feat/phase-2-x").phaseActive.n')" "2"
assert_eq "S3.6 — jalon v1.0 : icône, texte, phases 1 et 2" "$(G "$S" 'j.jalons.length+"|"+j.jalons[0].key+"|"+j.jalons[0].icone+"|"+j.jalons[0].phases.join()')" "1|v1.0 Test|🚧||1,|2"
assert_eq "S3.7 — arbre principal : étiquette, principal, courant ; l'autre : chemin relatif, non courant" "$(G "$S" 'j.arbres.map(a=>a.label+":"+a.principal+":"+a.courant).join("#")')" "arbre principal:true:true#../wt-2:false:false"
assert_eq "S3.8 — la mission rend ses nœuds (abandonnée) avec id, status, stage, deps" "$(G "$S" 'JSON.stringify(Object.keys(j.missions[0].noeuds[0]))')" '["id","status","step","stage","deps"]'
assert_eq "S3.9 — equipe : schéma cockpit-who@2 ; verrous lus (conductor voisin)" "$(G "$S" 'j.equipe.schema+"|"+j.verrous.etat')" "vibeflow/cockpit-who@2|lue"
assert_eq "S3.10 — tête : layout plat et projet" "$(G "$S" 'j.layout.forme+"|"+(typeof j.projet)')" "plat|string"

echo "=== S4 — sérialisation sans recalcul ==="
node "$AUX/q.mjs" "$SCRIPTS" "$L" "$FP/conductor/scripts" > "$WORK/q.json" 2>/dev/null
assert_eq "S4.0 — témoin : readPlanning rend l'avancement des deux phases et MISSION-1 abandonnee" "$(G "$WORK/q.json" 'j.phases.length+"|"+j.dags[0].etat')" "3|abandonnee"
assert_eq "S4.1 — avancement sérialisé sans recalcul" "$(node "$AUX/cmp.mjs" avancement "$S" "$WORK/q.json")" "OK"
assert_eq "S4.2 — état de mission sérialisé sans recalcul" "$(node "$AUX/cmp.mjs" etat "$S" "$WORK/q.json")" "OK"

echo "=== S5 — aucun réseau ==="
: > "$WORK/git.log"
PATH="$WORK/bin:$PATH" RUN "$FP" "$HOME" "$WORK/o5.json" "$L" > /dev/null
NLIG="$(grep -c . "$WORK/git.log")"; RESEAU="$(grep -cE '(^| )(fetch|pull|ls-remote|remote)( |$)' "$WORK/git.log")"
assert_eq "S5.1 — aucune sous-commande réseau de git (emballage vu à l'œuvre : au moins 5 appels)" "$([ "$NLIG" -ge 5 ] && echo vu || echo "aveugle:$NLIG")|$RESEAU" "vu|0"
PATH="$WORK/bin:$PATH" sh -c "git -C '$L' fetch origin >/dev/null 2>&1"
assert_eq "S5.2 — témoin positif : un fetch délibéré est journalisé" "$(grep -cE '(^| )fetch( |$)' "$WORK/git.log")" "1"
export VF_SONDE_OUT="$WORK/sonde.out"
: > "$VF_SONDE_OUT"; rm -f "$VF_SONDE_OUT.charge"
node --import "$AUX/sonde.mjs" "$AUX/temoin-sortant.mjs" >/dev/null 2>&1
assert_eq "S5.3 — témoin positif : la sonde enregistre un fetch et une connexion délibérés" "$(cut -d' ' -f1 "$VF_SONDE_OUT" | sort | tr '\n' ',')" "fetch,net,"
: > "$VF_SONDE_OUT"; rm -f "$VF_SONDE_OUT.charge"
node --import "$AUX/sonde.mjs" "$FP/cockpit/scripts/vf-cockpit-signal.mjs" "$L" > "$WORK/o5b.json" 2>/dev/null
assert_eq "S5.4 — émetteur : sonde chargée, 0 connexion sortante, résultat calculé" "$([ -s "$VF_SONDE_OUT.charge" ] && echo charge)|$(grep -c . "$VF_SONDE_OUT")|$(G "$WORK/o5b.json" 'j.schema')" "charge|0|vibeflow/cockpit-signal@1"

echo "=== S6 — résolution du verrou (P68-D-28) ==="
# lancé depuis la disposition FP : le conductor voisin est exécuté (même règle que W18.1 de test-cockpit-who.sh)
: > "$WORK/dl.log"; RUN "$FP" "$WORK/home-vide" "$WORK/o6a.json" "$L" > /dev/null
assert_eq "S6.1 — conductor voisin exécuté : verrous lus, journal du faux script non vide" "$(G "$WORK/o6a.json" 'j.verrous.etat')|$([ -s "$WORK/dl.log" ] && echo exécuté || echo muet)" "lue|exécuté"
# sans conductor voisin et sans HOME utile : source absente, mission inconnue
NV="$WORK/nv"; mkdisp "$NV" aucun
RUN "$NV" "$WORK/home-vide" "$WORK/o6b.json" "$L" > /dev/null
assert_eq "S6.2 — sans conductor voisin : verrous absente, mission inconnu, libellé « état inconnu »" "$(G "$WORK/o6b.json" 'j.verrous.etat+"|"+j.missions.find(m=>m.nom==="MISSION-1").etat+"|"+j.missions.find(m=>m.nom==="MISSION-1").libelle')" "absente|inconnu|état inconnu"
# scripts plantés dans un lab (conductor et .claude/scripts) : jamais exécutés, même avec HOME = le lab
LT="$WORK/lab-trap"; mkdir -p "$LT/.planning" "$LT/plugin/conductor/scripts" "$LT/.claude/scripts"
printf -- '- [ ] **Phase 1: Un** - a\n' > "$LT/.planning/ROADMAP.md"
for p in "$LT/plugin/conductor/scripts" "$LT/.claude/scripts"; do printf '#!/usr/bin/env bash\ntouch "%s/EXECUTE-$(basename "$(dirname "$(dirname "$0")")")"\necho "{\\"present\\": false}"\n' "$WORK" > "$p/driver-lock.sh"; chmod +x "$p/driver-lock.sh"; done
G_ -C "$LT" init -q -b main
bash "$LT/plugin/conductor/scripts/driver-lock.sh" status >/dev/null 2>&1
assert_eq "S6.0 — témoin positif : le script planté laisse bien son fichier témoin quand on le lance" "$(ls "$WORK" | grep -c '^EXECUTE-')" "1"
rm -f "$WORK"/EXECUTE-*
RUN "$NV" "$LT" "$WORK/o6c.json" "$LT" > /dev/null
assert_eq "S6.3 — script planté dans le lab jamais exécuté" "$(ls "$WORK" | grep -c '^EXECUTE-')" "0"
assert_eq "S6.3b — et la source des verrous est absente (la sortie existe, le script planté n'a pas répondu)" "$(G "$WORK/o6c.json" 'j.verrous.etat')" "absente"
BAD="$WORK/bad"; mkdisp "$BAD" texte
RUN "$BAD" "$WORK/home-vide" "$WORK/o6d.json" "$L" > /dev/null
assert_eq "S6.4 — source des verrous illisible : mission inconnu" "$(G "$WORK/o6d.json" 'j.verrous.etat+"|"+j.missions.find(m=>m.nom==="MISSION-1").etat')" "erreur|inconnu"

echo "=== S7 — bornes ==="
assert_eq "S7.1 — une étape de nœud de 500 caractères sort bornée à 100" "$(G "$S" 'j.missions.find(m=>m.nom==="MISSION-1").noeuds[0].step.length')" "100"
ESC=$'\033'
WE="$WORK/wt-${ESC}[31mpiege"; G_ -C "$L" worktree add -q --detach "$WE" main 2>/dev/null
RUN "$FP" "$HOME" "$WORK/o7.json" "$L" > /dev/null
assert_eq "S7.2 — un worktree au nom piégé : listé, étiquette sans caractère de contrôle" "$(G "$WORK/o7.json" 'j.arbres.length+"|"+j.arbres.some(a=>a.label.includes("piege"))+"|"+j.arbres.some(a=>/[\u0000-\u001f\u007f-\u009f]/.test(a.label+a.branche))')" "3|true|false"
assert_eq "S7.3 — sans argument : exit 2" "$(RUN "$FP" "$HOME" "$WORK/o7a.json")" "2"
assert_eq "S7.4 — racine absente : exit 2" "$(RUN "$FP" "$HOME" "$WORK/o7b.json" "$WORK/inexistant")" "2"
assert_eq "S7.5 — --plugin-root (retirée, P68-D-28) refusée comme toute option : exit 2, ligne d'usage sur stderr" "$(RUN "$FP" "$HOME" "$WORK/o7c.json" "$L" --plugin-root "$WORK/plugin")|$(grep -c . "$WORK/o7c.json.err" | tr -d ' ' | sed 's/^0$/muet/;s/^[1-9].*/usage/')" "2|usage"
assert_eq "S7.6 — option inconnue : exit 2, stdout vide" "$(RUN "$FP" "$HOME" "$WORK/o7d.json" "$L" --json)|$(wc -c < "$WORK/o7d.json" | tr -d ' ')" "2|0"

echo "=== S8 — copies mutées ==="
# M1 : l'état de mission est recalculé depuis les seuls nœuds ; M2 : l'avancement est recalculé (version réécrite)
mutant() { # <nom> <de> <vers> -> disposition $WORK/mut-<nom>, rend « muté » / « ancre absente » / « ancre ambiguë »
  local d="$WORK/mut-$1"; mkdisp "$d" vrai
  local f="$d/cockpit/scripts/vf-cockpit-signal.mjs"
  [ -f "$f" ] || { echo "ancre absente"; return; }
  [ "$(grep -cF -- "$2" "$f")" = "1" ] || { echo "ancre ambiguë"; return; }
  FROM="$2" TO="$3" node "$AUX/mutsub.mjs" "$f"
}
M1="$(mutant m1 'etat: d.etat, libelle' "etat: (d.nodes.some((n) => n?.status === 'running') ? 'running' : d.etat), libelle")"
RUN "$WORK/mut-m1" "$HOME" "$WORK/om1.json" "$L" > /dev/null
M1A="$(G "$WORK/om1.json" 'j.missions.find(m=>m.nom==="MISSION-1").etat')"
M1B="$(node "$AUX/cmp.mjs" etat "$WORK/om1.json" "$WORK/q.json")"
M2="$(mutant m2 'avancement: p.avancement, libelle' 'avancement: { ...p.avancement, version: 3 }, libelle')"
RUN "$WORK/mut-m2" "$HOME" "$WORK/om2.json" "$L" > /dev/null
M2A="$(node "$AUX/cmp.mjs" avancement "$WORK/om2.json" "$WORK/q.json")"
assert_eq "S8.0 — les deux copies ont bien été mutées (ancre unique trouvée)" "$M1|$M2" "muté|muté"
assert_eq "S8.1 — copie mutée qui recalcule : détectée (S3.2 rougit, S4.2 rougit, pas une panne)" "$([ "$M1A" = running ] && echo S3.2-rouge)|$(echo "$M1B" | cut -c1-22)" "S3.2-rouge|KO mission MISSION-1 : "
assert_eq "S8.2 — copie mutée qui recalcule l'avancement : S4.1 rougit sur une phase, pas une panne" "$(echo "$M2A" | cut -c1-9)" "KO phase "

vf_hyg_assert
echo
echo "=== Résultats : $PASS PASS, $FAIL FAIL ==="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée"; exit 1; fi
[ "$FAIL" -eq 0 ]
