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
assert_eq "S2.4 — le contrat déclare schema dans requis et les cinq interdits (dont fil, AUDC-D8)" "$(G "$IFACE" 'j.schemas["vibeflow/cockpit-signal@1"]?.requis?.schema+"|"+(j.schemas["vibeflow/cockpit-signal@1"]?.interdits||[]).join()')" "string|doing,mandat,messages,outils,fil"

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
assert_eq "S8.1 — copie mutée qui recalcule : détectée (S3.2 rougit, S4.2 rougit, pas une panne)" "$([ "$M1A" = running ] && echo S3.2-rouge)|$(echo "$M1B" | cut -c1-22)" "S3.2-rouge|KO mission MISSION-1 :"
assert_eq "S8.2 — copie mutée qui recalcule l'avancement : S4.1 rougit sur une phase, pas une panne" "$(echo "$M2A" | cut -c1-9)" "KO phase "

echo "=== S9 — toute chaîne issue du disque sort nettoyée et bornée, quel que soit le champ (F-02) ==="
# Famille : pour chaque scénario, un caractère de contrôle (et une longueur démesurée) est posé dans une source écrite par d'autres ;
# chaque champ de la liste est lu dans la sortie réelle de l'émetteur : il doit exister, sans contrôle, sous sa borne. Un balayage global
# vérifie ensuite TOUTES les chaînes de la sortie (borne générale 1024) : un champ ajouté demain est couvert sans qu'on y pense.
cat > "$AUX/famille.mjs" <<'JS'
// famille.mjs <signal.json> <expr@borne>... : une ligne « expr=verdict » par champ, puis « *=verdict » pour le balayage global
import fs from 'node:fs';
const [, , f, ...champs] = process.argv;
let j; try { j = JSON.parse(fs.readFileSync(f, 'utf8')); } catch { console.log('*=illisible'); process.exit(0); }
const CTL = /[\u0000-\u001f\u007f-\u009f]/;
for (const c of champs) {
  const [expr, max] = c.split('@'); let v; try { v = new Function('j', 'return (' + expr + ')')(j); } catch { v = undefined; }
  console.log(expr + '=' + (typeof v !== 'string' || !v ? 'inaccessible' : CTL.test(v) ? 'controle' : v.length > Number(max) ? 'long:' + v.length : 'ok'));
}
let ctl = 0, long = 0, n = 0;
const marche = (o) => { if (typeof o === 'string') { n++; if (CTL.test(o)) ctl++; if (o.length > 1024) long++; } else if (o && typeof o === 'object') for (const v of Object.values(o)) marche(v); };
marche(j);
console.log('*=' + (n < 20 ? 'vide' : ctl || long ? `controle:${ctl} long:${long}` : 'ok'));
JS
FAM() { # FAM <etiquette> <signal.json> <expr@borne>... : une assertion par champ + le balayage global
  local et="$1" f="$2"; shift 2
  local ligne
  while IFS= read -r ligne; do
    assert_eq "$et — ${ligne%%=*}" "${ligne#*=}" "ok"
  done <<< "$(node "$AUX/famille.mjs" "$f" "$@")"
}
LONGW="$(printf 'w%.0s' $(seq 1 120))"
# (A) phaseActive.nom : le ROADMAP d'un AUTRE worktree
L9="$WORK/lab-s9a"; W9="$WORK/wt-s9a"
G_ init -q -b main "$L9"; mkdir -p "$L9/.planning"
printf -- '- [ ] **Phase 1: Un** - a\n- [ ] **Phase 2: Deux** - b\n' > "$L9/.planning/ROADMAP.md"
G_ -C "$L9" add -A; G_ -C "$L9" commit -q -m c0; G_ -C "$L9" branch feat/phase-2-x; G_ -C "$L9" worktree add -q "$W9" feat/phase-2-x 2>/dev/null
printf -- '- [ ] **Phase 1: Un** - a\n- [ ] **Phase 2: %s]0;pwn%s%s[31mDeux%s** - b\n' "$ESC" $'\a' "$ESC" "$(printf 'y%.0s' $(seq 1 200))" > "$W9/.planning/ROADMAP.md"
RUN "$FP" "$HOME" "$WORK/o9a.json" "$L9" > /dev/null
FAM "S9.A" "$WORK/o9a.json" 'j.arbres[1].phaseActive.nom@90' 'j.arbres[1].label@200'
# (B) missions[].ws : le champ ws du JSON d'un DAG
L9b="$WORK/lab-s9b"; G_ init -q -b main "$L9b"; mkdir -p "$L9b/.planning/missions"
printf -- '- [ ] **Phase 1: Un** - a\n' > "$L9b/.planning/ROADMAP.md"
printf '{"ws":"%s[31m%s","nodes":[{"id":"a","step":"s","deps":[],"status":"done"}]}\n' '\u001b' "$(printf 'a%.0s' $(seq 1 100000))" > "$L9b/.planning/missions/MISSION-1.dag.json"
RUN "$FP" "$HOME" "$WORK/o9b.json" "$L9b" > /dev/null
FAM "S9.B" "$WORK/o9b.json" 'j.missions[0].ws@80'
# (C) noms de compartiment et fichier active-workstream
NOMC="${ESC}[31m${LONGW}"
L9c="$WORK/lab-s9c"; G_ init -q -b main "$L9c"; mkdir -p "$L9c/.planning/workstreams/$NOMC"
printf -- '## Milestones\n\n- 🚧 **v1.0 Test** - Phases 1-1\n\n## Phases\n\n- [ ] **Phase 1: Un** - a\n' > "$L9c/.planning/workstreams/$NOMC/ROADMAP.md"
printf '{"nodes":[{"id":"a","step":"s","deps":[],"status":"done"}]}\n' > "$L9c/.planning/workstreams/$NOMC/MISSION-1.dag.json"
printf '%s\n' "$NOMC" > "$L9c/.planning/active-workstream"
RUN "$FP" "$HOME" "$WORK/o9c.json" "$L9c" > /dev/null
FAM "S9.C" "$WORK/o9c.json" 'j.phases[0].ws@80' 'j.phases[0].key@1024' 'j.jalons[0].ws@80' 'j.jalons[0].phases[0]@1024' 'j.layout.actif@80' 'j.missions[0].ws@80' 'j.missions[0].phaseKey@1024'
# (D) racine du lab dont le nom porte un caractère de contrôle
L9d="$WORK/lab-s9d-${ESC}[31m$(printf 'r%.0s' $(seq 1 20))"; G_ init -q -b main "$L9d"; mkdir -p "$L9d/.planning"
printf -- '- [ ] **Phase 1: Un** - a\n' > "$L9d/.planning/ROADMAP.md"
RUN "$FP" "$HOME" "$WORK/o9d.json" "$L9d" > /dev/null
FAM "S9.D" "$WORK/o9d.json" 'j.root@1024' 'j.equipe.root@1024'

# copie mutée : sans la passe finale, les champs sans borne propre (clés de phase, compartiment dans les jalons) laissent passer le contrôle ; le balayage doit le voir
MS9="$(mutant s9 'return assainir({' 'return ({')"
RUN "$WORK/mut-s9" "$HOME" "$WORK/o9m.json" "$L9c" > /dev/null
assert_eq "S9.M — copie mutée (sans passe finale) détectée : le balayage global rougit sur le contrôle, ce n'est pas une panne" "$MS9|$(node "$AUX/famille.mjs" "$WORK/o9m.json" | tail -1 | cut -c1-11)" "muté|*=controle:"

echo "=== S10 — lab plat : la vie d'une mission se lit sur le verrou de SON arbre (F-05) ==="
# En lab plat le verrou est propre à chaque checkout (.planning/DRIVER.lock). Faux driver-lock.sh de forme réelle (json_status, lab plat : ni scope ni ws)
# qui répond selon le dossier courant. Le même DAG (MISSION-2, nœud running) est dans les deux checkouts ; phaseActive d'un arbre sans branche en `phase-N`
# est la dernière phase portant une mission running : elle dit donc si la mission de CET arbre est vivante.
FD5="$WORK/plugin5"; mkdisp "$FD5" aucun; mkdir -p "$FD5/conductor/scripts"
cat > "$FD5/conductor/scripts/driver-lock.sh" <<'SH'
#!/usr/bin/env bash
case "$1" in
  status) if [ -d .planning/DRIVER.lock ]; then echo '{"present": true, "owner": "mgr-plat", "step": "exec", "age_seconds": 10, "ttl": 1800, "stale": false, "generation": "g1", "session_ids": [], "lease_seconds": 5, "guard_effective": false, "progress_epoch": null, "progress_age_seconds": 3, "children_running": 0}'; else echo '{"present": false, "lock": ".planning/DRIVER.lock", "children_running": 0}'; fi ;;
  orphans) echo '{"orphans":[]}' ;;
esac
SH
chmod +x "$FD5/conductor/scripts/driver-lock.sh"
L5="$WORK/lab-s10"; W5="$WORK/wt-s10"
G_ init -q -b main "$L5"; mkdir -p "$L5/.planning/missions"
printf -- '- [ ] **Phase 1: Un** - a\n- [ ] **Phase 2: Deux** - b\n' > "$L5/.planning/ROADMAP.md"
printf '{"nodes":[{"id":"a","step":"s","stage":"exec","deps":[],"status":"running"}]}\n' > "$L5/.planning/missions/MISSION-2.dag.json"
G_ -C "$L5" add -A; G_ -C "$L5" commit -q -m c0; G_ -C "$L5" branch feat/x; G_ -C "$L5" worktree add -q "$W5" feat/x 2>/dev/null
PA() { G "$1" "j.arbres.map(a=>a.branche+\":\"+(a.phaseActive?a.phaseActive.n:\"aucune\")).join(\"#\")"; }
assert_eq "S10.0 — témoin : le faux script répond selon le dossier (verrou tenu seulement là où .planning/DRIVER.lock existe)" "$(cd "$L5" && bash "$FD5/conductor/scripts/driver-lock.sh" status | cut -c1-17)|$(mkdir -p "$L5/.planning/DRIVER.lock"; cd "$L5" && bash "$FD5/conductor/scripts/driver-lock.sh" status | cut -c1-17)|$(cd "$W5" && bash "$FD5/conductor/scripts/driver-lock.sh" status | cut -c1-17)" '{"present": false|{"present": true,|{"present": false'
RUN "$FD5" "$WORK/home-vide" "$WORK/o10a.json" "$L5" > /dev/null
assert_eq "S10.1 — verrou tenu dans l'arbre principal seulement : sa mission est vivante (phase 2), celle du worktree est abandonnée (aucune phase active)" "$(PA "$WORK/o10a.json")" "main:2#feat/x:aucune"
rmdir "$L5/.planning/DRIVER.lock"; mkdir -p "$W5/.planning/DRIVER.lock"
RUN "$FD5" "$WORK/home-vide" "$WORK/o10b.json" "$L5" > /dev/null
assert_eq "S10.2 — verrou tenu dans le worktree seulement : l'inverse" "$(PA "$WORK/o10b.json")" "main:aucune#feat/x:2"

echo "=== S11 — échéance globale de l'émetteur, indépendante du nombre d'arbres (F-06) ==="
# git est ralenti (0,5 s par appel) sur un lab à six arbres : sans échéance globale le total croît avec le nombre d'arbres ; avec echeanceMs il est borné
# et les champs non calculés à temps sont null (jamais 0). Témoin de contrôle : avec une échéance généreuse tout est calculé, et c'est lent.
cat > "$AUX/ech.mjs" <<'JS'
// ech.mjs <scripts> <lab> <echeanceMs> <dossier de scripts du verrou> : collectSignal avec échéance ; durée et retard.main de chaque arbre
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, root, ech, sd] = process.argv;
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-signal.mjs')).href);
const t0 = Date.now();
const s = m.collectSignal(root, { home: process.env.HOME, scriptsDir: sd, echeanceMs: Number(ech) });
console.log(JSON.stringify({ ms: Date.now() - t0, arbres: s.arbres.length, main: s.arbres.map((a) => (a.retard && typeof a.retard.main === 'number' ? a.retard.main : null)) }));
JS
mkdir -p "$WORK/binslow"
printf '#!/bin/sh\nsleep 0.5\nexec "%s" "$@"\n' "$GIT_REEL" > "$WORK/binslow/git"; chmod +x "$WORK/binslow/git"
L6="$WORK/lab-s11"; G_ init -q -b main "$L6"; mkdir -p "$L6/.planning"
printf -- '- [ ] **Phase 1: Un** - a\n' > "$L6/.planning/ROADMAP.md"
G_ -C "$L6" add -A; G_ -C "$L6" commit -q -m c0
for i in 1 2 3 4 5; do G_ -C "$L6" branch "b$i"; G_ -C "$L6" worktree add -q "$WORK/wt-s11-$i" "b$i" 2>/dev/null; done
for i in 1 2 3; do G_ -C "$L6" commit -q --allow-empty -m "m$i"; done
ECH() { PATH="$WORK/binslow:$PATH" node "$AUX/ech.mjs" "$SCRIPTS" "$L6" "$1" "$FP/conductor/scripts" 2>/dev/null; }   # ECH <echeanceMs>
ECHJ() { node -e 'const j=JSON.parse(require("fs").readFileSync(0,"utf8"));console.log(eval(process.argv[1]))' "$1"; }
E_LARGE="$(ECH 600000)"
assert_eq "S11.1 — témoin : échéance généreuse, six arbres, retard.main calculé partout (0 pour l'arbre principal, 3 pour les cinq autres) et lent (au moins 8 s)" "$(echo "$E_LARGE" | ECHJ 'j.arbres+"|"+j.main.join()+"|"+(j.ms>=8000)')" "6|0,3,3,3,3,3|true"
E_COURT="$(ECH 3000)"
assert_eq "S11.2 — échéance de 3 s : l'émetteur rend en moins de 6 s" "$(echo "$E_COURT" | ECHJ 'j.ms<6000')" "true"
assert_eq "S11.3 — échéance de 3 s : les six arbres sont listés, au moins un retard.main non calculé à temps vaut null (jamais un 0 pour un arbre en retard)" "$(echo "$E_COURT" | ECHJ 'j.arbres+"|"+(j.main.some(x=>x===null))+"|"+(j.main.slice(1).some(x=>x===0))')" "6|true|false"

echo "=== S12 — mission.vie null : le sens se lit sur mission.etat, et le contrat le dit (F-08) ==="
# vie null = « pas de verrou lu pour cette mission » ; deux causes, distinguées par etat : `inconnu` (nœud running, source des verrous illisible)
# ou done/ready/failed (aucun nœud running : les verrous ne sont pas lus). Une mission running/abandonnee a toujours une vie. Le contrat porte la liste (mission.vieNulle).
L12="$WORK/lab-s12"; G_ init -q -b main "$L12"; mkdir -p "$L12/.planning/missions"
printf -- '- [ ] **Phase 1: Un** - a\n' > "$L12/.planning/ROADMAP.md"
printf '{"nodes":[{"id":"a","step":"s","stage":"exec","deps":[],"status":"running"}]}\n' > "$L12/.planning/missions/MISSION-A-actif.dag.json"
printf '{"nodes":[{"id":"a","step":"s","stage":"exec","deps":[],"status":"done"}]}\n' > "$L12/.planning/missions/MISSION-B-faite.dag.json"
printf '{"nodes":[{"id":"a","step":"s","stage":"exec","deps":[],"status":"pending"}]}\n' > "$L12/.planning/missions/MISSION-C-prete.dag.json"
printf '{"nodes":[{"id":"a","step":"s","stage":"exec","deps":[],"status":"failed"}]}\n' > "$L12/.planning/missions/MISSION-D-echec.dag.json"
VN() { G "$1" 'j.missions.map(m=>m.nom.slice(-6)+":"+m.etat+":"+(m.vie===null)).sort().join()'; }
RUN "$FP" "$WORK/home-vide" "$WORK/o12a.json" "$L12" > /dev/null
assert_eq "S12.1 — verrous lus (conductor voisin, aucun verrou tenu) : la mission au nœud running est abandonnee et porte une vie ; les trois autres ont vie null sans être inconnu" "$(VN "$WORK/o12a.json")" "-actif:abandonnee:false,-echec:failed:true,-faite:done:true,-prete:ready:true"
RUN "$NV" "$WORK/home-vide" "$WORK/o12b.json" "$L12" > /dev/null
assert_eq "S12.2 — source des verrous illisible (aucun conductor) : la mission au nœud running est inconnu, vie null ; les trois autres inchangées (vie null aussi)" "$(VN "$WORK/o12b.json")" "-actif:inconnu:true,-echec:failed:true,-faite:done:true,-prete:ready:true"
assert_eq "S12.3 — le contrat versionné déclare les états de mission dont vie vaut null (mission.vieNulle)" "$(G "$IFACE" '(j.schemas["vibeflow/cockpit-signal@1"].mission.vieNulle||["absent"]).slice().sort().join()')" "done,failed,inconnu,ready"
assert_eq "S12.4 — l'en-tête de vf-cockpit-avancement.mjs dit que vie: null a deux sens départagés par etat (vieNulle)" "$(grep -c 'vie: null.*DEUX sens.*etat.*vieNulle' "$SCRIPTS/vf-cockpit-avancement.mjs" | sed 's/^[1-9].*/dit/')" "dit"

echo "=== S13 — passe finale bornée, échéance à 0 ms (passe 2, RV-4, RV-5) ==="
# Les entrées réelles sont déjà bornées en amont (un chemin ne dépasse pas PATH_MAX) : la borne générale se prouve sur la fonction elle-même.
cat > "$AUX/brn.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts] = process.argv;
const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
const s = await imp('vf-cockpit-signal.mjs'), p = await imp('vf-cockpit-paths.mjs');
const o = s.assainir({ a: [{ b: 'x'.repeat(5000) }], c: 'y\u001b[31mz', n: 3, f: false, v: null });
const t0 = Date.now(); const sortie = p.avecEcheance(0, () => p.shBorne('node', ['-e', 'console.log("lance")']));
console.log(JSON.stringify({ borne: s.BORNE_GENERALE, long: o.a[0].b.length, ctl: o.c, passe: [o.n, o.f, o.v], zero: sortie, rapide: Date.now() - t0 < 1500 }));
JS
node "$AUX/brn.mjs" "$SCRIPTS" > "$WORK/o13.json" 2>/dev/null
assert_eq "S13.1 — assainir : une chaîne de 5000 caractères sort à 1024, le contrôle est retiré, nombre, booléen et null passent" "$(G "$WORK/o13.json" 'j.borne+"|"+j.long+"|"+j.ctl+"|"+JSON.stringify(j.passe)')" '1024|1024|y[31mz|[3,false,null]'
M131="$(mutant b1 'export const BORNE_GENERALE = 1024;' 'export const BORNE_GENERALE = 1000000;')"
node "$AUX/brn.mjs" "$WORK/mut-b1/cockpit/scripts" > "$WORK/o13m.json" 2>/dev/null
assert_eq "S13.2 — copie mutée (borne 1 000 000) détectée : la chaîne de 5000 caractères n'est plus bornée" "$M131|$(G "$WORK/o13m.json" 'j.long>1024')" "muté|true"
assert_eq "S13.3 — échéance à 0 ms : shBorne ne lance rien (sortie vide) et rend aussitôt" "$(G "$WORK/o13.json" 'JSON.stringify(j.zero)+"|"+j.rapide')" '""|true'

vf_hyg_assert
echo
echo "=== S14 — le verrou de dépôt posé par le VRAI driver-lock.sh fait vivre la mission (P68-D-33, F-01) ==="
# Lab partitionné jetable, conductor voisin = copie du vrai driver-lock.sh ; `acquire` sans --ws pose un verrou de portée depot, puis l'émetteur réel lit.
DR="$WORK/plugin-reel"; mkdisp "$DR" aucun; mkdir -p "$DR/conductor"; cp -R "$SCRIPTS/../../conductor/scripts" "$DR/conductor/scripts"; mkdir -p "$DR/planning-core"; cp -R "$SCRIPTS/../../planning-core/scripts" "$DR/planning-core/scripts"
L14="$WORK/lab14"; mkdir -p "$L14/.planning/workstreams/w"
printf -- '- [ ] **Phase 1: Un** - a\n' > "$L14/.planning/workstreams/w/ROADMAP.md"
printf '{"nodes":[{"id":"a","step":"s","stage":"exec","deps":[],"status":"running"}]}\n' > "$L14/.planning/workstreams/w/MISSION-1.dag.json"
echo w > "$L14/.planning/active-workstream"
G_ init -q -b main "$L14"; G_ -C "$L14" add -A; G_ -C "$L14" -c user.name=t -c user.email=t@t commit -q -m c0
mkdir -p "$WORK/home14"
ACQ14="$(cd "$L14" && HOME="$WORK/home14" bash "$DR/conductor/scripts/driver-lock.sh" acquire --owner=t --step=s 2>/dev/null)"
RUN "$DR" "$WORK/home14" "$WORK/o14.json" "$L14" > /dev/null
assert_eq "S14.1 — témoin : acquire sans --ws pose un verrou de portée depot, et l'émetteur le lit (verrous.etat lue)" "$(printf '%s' "$ACQ14" | node -e 'const j=JSON.parse(require("fs").readFileSync(0,"utf8"));console.log(j.scope+":"+j.scope_reason)')|$(G "$WORK/o14.json" 'j.verrous.etat')" "depot:ws-absent|lue"
assert_eq "S14.2 — lab partitionné, verrou de dépôt tenu : la mission du compartiment w est running (jamais abandonnee)" "$(G "$WORK/o14.json" 'j.missions.map(m=>m.nom+":"+m.etat).join()')" "MISSION-1:running"
(cd "$L14" && HOME="$WORK/home14" bash "$DR/conductor/scripts/driver-lock.sh" release --depot --owner=t >/dev/null 2>&1)
RUN "$DR" "$WORK/home14" "$WORK/o14b.json" "$L14" > /dev/null
assert_eq "S14.3 — contre-épreuve : verrou de dépôt relâché, la même mission est abandonnee" "$(G "$WORK/o14b.json" 'j.missions.map(m=>m.nom+":"+m.etat).join()')" "MISSION-1:abandonnee"

echo "=== Résultats : $PASS PASS, $FAIL FAIL ==="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée"; exit 1; fi
[ "$FAIL" -eq 0 ]
