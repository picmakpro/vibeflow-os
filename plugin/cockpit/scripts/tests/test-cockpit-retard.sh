#!/usr/bin/env bash
# test-cockpit-retard.sh — retard sur la branche de base et worktrees, sans réseau (VFSG-05 ; P68-D-04)
#   R0 contrôles positifs des fixtures (git réel, avant tout appel au module)
#   R1 retard local d'un arbre sur la base locale · R2 retard sur origin/<base> local, âge du dernier fetch, références absentes
#   R3 worktrees : une entrée par arbre, branche, détaché · R4 phase active (branche, mission running, phase en-cours, jamais le STATE)
#   R5 aucune sous-commande réseau de git, aucune connexion sortante (témoins positifs) · R6 chaînes nettoyées
#   R7 non-régression de test-cockpit-who.sh
# Fixtures construites par la suite dans mktemp, jamais de dépôt distant. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t.test GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t.test
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
TESTS="$SCRIPTS/tests"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/bin"
GIT_REEL="$(command -v git)"

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (a trouvé [$3])"; FAIL=$((FAIL+1)); fi; }

# --- outils node écrits par la suite ---
# q.mjs <scripts> <fonction> <json des arguments positionnels> : appelle l'export nommé ; la chaîne "NOW" devient Date.now()
cat > "$AUX/q.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, fn, json] = process.argv;
let m; try { m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-arbres.mjs')).href); } catch { console.log('module absent'); process.exit(0); }
if (typeof m[fn] !== 'function') { console.log('export absent'); process.exit(0); }
const sub = (v) => (v === 'NOW' ? Date.now() : Array.isArray(v) ? v.map(sub) : v && typeof v === 'object' ? Object.fromEntries(Object.entries(v).map(([k, x]) => [k, sub(x)])) : v);
console.log(JSON.stringify(m[fn](...sub(JSON.parse(json || '[]')))));
JS
cat > "$AUX/get.mjs" <<'JS'
let j; try { j = JSON.parse(process.argv[2] || 'null'); } catch { console.log(process.argv[2]); process.exit(0); } // non-JSON (« module absent », « export absent ») : rendu tel quel
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
G() { node "$AUX/get.mjs" "$1" "$2" 2>/dev/null || echo "illisible"; }
Q() { node "$AUX/q.mjs" "$SCRIPTS" "$1" "$2" 2>/dev/null; }
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
# emballage git : journalise l'argv puis exécute le vrai git
cat > "$WORK/bin/git" <<EOS
#!/bin/sh
printf '%s\n' "\$*" >> "$WORK/git.log"
exec "$GIT_REEL" "\$@"
EOS
chmod +x "$WORK/bin/git"

# --- fixtures ---
G_() { "$GIT_REEL" "$@"; }
D="$WORK/depot"; W="$WORK/wt-2"
G_ init -q -b main "$D"
G_ -C "$D" commit -q --allow-empty -m c0
G_ -C "$D" branch feat/phase-2-x
G_ -C "$D" worktree add -q "$W" feat/phase-2-x 2>/dev/null
for i in 1 2 3; do G_ -C "$D" commit -q --allow-empty -m "m$i"; done          # main = c0 + 3
G_ -C "$D" checkout -q -b tmp-o main 2>/dev/null
for i in 1 2; do G_ -C "$D" commit -q --allow-empty -m "o$i"; done             # tmp-o = main + 2 = c0 + 5
G_ -C "$D" update-ref refs/remotes/origin/main "$(G_ -C "$D" rev-parse tmp-o)"
G_ -C "$D" checkout -q main; G_ -C "$D" branch -q -D tmp-o
HIER="$(date -v-2H +%Y%m%d%H%M 2>/dev/null || date -d '2 hours ago' +%Y%m%d%H%M)"
echo "abc	not-for-merge	branch 'main' of x" > "$D/.git/FETCH_HEAD"; touch -t "$HIER" "$D/.git/FETCH_HEAD"
COM="$D/.git"

echo "=== R0 — contrôles positifs des fixtures ==="
assert_eq "R0.1 — fixture : l'arbre W est en retard de 3 commits sur main (git réel)" "$(G_ -C "$W" rev-list --count HEAD..main)" "3"
assert_eq "R0.2 — fixture : origin/main a 5 commits d'avance sur W (git réel)" "$(G_ -C "$W" rev-list --count HEAD..origin/main)" "5"
assert_eq "R0.3 — fixture : FETCH_HEAD existe et date d'environ deux heures" "$([ -f "$COM/FETCH_HEAD" ] && echo oui)" "oui"
assert_eq "R0.4 — fixture : git worktree list voit deux arbres" "$(G_ -C "$D" worktree list --porcelain | grep -c '^worktree ')" "2"

echo "=== R1 — retard local ==="
R1="$(Q retard "[{\"chemin\":\"$W\",\"base\":\"main\",\"commonDir\":\"$COM\",\"now\":\"NOW\"}]")"
assert_eq "R1.1 — arbre en retard de 3 commits sur main : main = 3" "$(G "$R1" 'j.main')" "3"
assert_eq "R1.2 — la base est rendue telle quelle" "$(G "$R1" 'j.base')" "main"
R1B="$(Q retard "[{\"chemin\":\"$D\",\"base\":\"main\",\"commonDir\":\"$COM\",\"now\":\"NOW\"}]")"
assert_eq "R1.3 — l'arbre principal n'a aucun retard sur main : main = 0" "$(G "$R1B" 'j.main')" "0"
R1C="$(Q retard "[{\"chemin\":\"$W\",\"base\":null,\"commonDir\":\"$COM\",\"now\":\"NOW\"}]")"
assert_eq "R1.4 — sans base : main = null, origin = null (jamais 0)" "$(G "$R1C" '[j.main,j.origin]')" "[null,null]"

echo "=== R2 — origin local et âge du dernier fetch ==="
assert_eq "R2.1 — retard sur origin/main local : origin = 5" "$(G "$R1" 'j.origin')" "5"
assert_eq "R2.2 — âge du fetch entre 7100 et 7300 s" "$(G "$R1" 'j.fetchAgeS>=7100&&j.fetchAgeS<=7300')" "true"
R2B="$(Q retard "[{\"chemin\":\"$W\",\"base\":\"main\",\"commonDir\":\"$WORK/inexistant\",\"now\":\"NOW\"}]")"
assert_eq "R2.3 — sans FETCH_HEAD : fetchAgeS = null (jamais 0)" "$(G "$R2B" 'j.fetchAgeS')" "null"
RO="$(G_ -C "$D" rev-parse refs/remotes/origin/main)"; G_ -C "$D" update-ref -d refs/remotes/origin/main
R2C="$(Q retard "[{\"chemin\":\"$W\",\"base\":\"main\",\"commonDir\":\"$COM\",\"now\":\"NOW\"}]")"
assert_eq "R2.4 — sans origin/main : origin = null, main reste 3" "$(G "$R2C" '[j.origin,j.main]')" "[null,3]"
G_ -C "$D" update-ref refs/remotes/origin/main "$RO"
assert_eq "R2.5 — brancheBase sans origin/HEAD : main local" "$(G "$(Q brancheBase "[\"$D\"]")" 'j')" "main"
G_ -C "$D" branch -q trunk main; G_ -C "$D" update-ref refs/remotes/origin/trunk "$(G_ -C "$D" rev-parse main)"
G_ -C "$D" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/trunk
assert_eq "R2.6 — brancheBase suit refs/remotes/origin/HEAD (privé de origin/)" "$(G "$(Q brancheBase "[\"$D\"]")" 'j')" "trunk"
G_ -C "$D" symbolic-ref --delete refs/remotes/origin/HEAD; G_ -C "$D" update-ref -d refs/remotes/origin/trunk; G_ -C "$D" branch -q -D trunk
G_ -C "$D" branch -q -m main autre-nom
assert_eq "R2.7 — ni origin/HEAD ni main local : brancheBase = null" "$(G "$(Q brancheBase "[\"$D\"]")" 'j')" "null"
G_ -C "$D" branch -q -m autre-nom main

echo "=== R3 — worktrees ==="
R3="$(Q arbresGit "[\"$D\"]")"
assert_eq "R3.1 — deux worktrees : deux entrées" "$(G "$R3" 'j.length')" "2"
assert_eq "R3.2 — branches main et feat/phase-2-x, dans l'ordre de git" "$(G "$R3" 'j.map(a=>a.branche)')" '["main","feat/phase-2-x"]'
assert_eq "R3.3 — principal vrai pour la seule première entrée" "$(G "$R3" 'j.map(a=>a.principal)')" "[true,false]"
WD="$WORK/wt-det"; G_ -C "$D" worktree add -q --detach "$WD" main 2>/dev/null
assert_eq "R3.4 — un worktree détaché rend (détachée)" "$(G "$(Q arbresGit "[\"$D\"]")" 'j.find(a=>a.chemin.endsWith("wt-det")).branche')" "(détachée)"
assert_eq "R3.5 — le dépôt non git rend le repli [root]" "$(G "$(Q arbresGit "[\"$WORK/aux\"]")" 'j.length+"|"+j[0].principal')" "1|true"

echo "=== R4 — phase active ==="
PH='[{"key":"|1","n":"1","name":"Un","avancement":{"etat":"fait","mission":null}},{"key":"|2","n":"2","name":"Deux","avancement":{"etat":"a-faire","mission":null}},{"key":"|3","n":"3","name":"Trois","avancement":{"etat":"en-cours","mission":{"nom":"M3","etat":"running"}}},{"key":"|4","n":"4","name":"Quatre","avancement":{"etat":"en-cours","mission":null}}]'
# le JSON est assemblé dans une variable : bash 3.2 mal-analyse des guillemets imbriqués dans $( )
PA() { local a="[{\"phases\":$1,\"branche\":\"$2\"}]"; local r; r="$(Q phaseActive "$a")"; G "$r" "$3"; }
assert_eq "R4.1 — branche feat/phase-2-x et phase 2 connue : phase 2" "$(PA "$PH" feat/phase-2-x 'j.n+"|"+j.nom+"|"+j.etat+"|"+j.key')" "2|Deux|a-faire||2"
assert_eq "R4.2 — branche main : la phase à mission running (3)" "$(PA "$PH" main 'j.n')" "3"
PH2='[{"key":"|1","n":"1","name":"Un","avancement":{"etat":"fait","mission":null}},{"key":"|4","n":"4","name":"Quatre","avancement":{"etat":"en-cours","mission":{"nom":"M","etat":"abandonnee"}}}]'
assert_eq "R4.3 — aucune mission running : la dernière phase en-cours (4)" "$(PA "$PH2" main 'j.n')" "4"
PH3='[{"key":"|1","n":"1","name":"Un","avancement":{"etat":"fait","mission":null}}]'
assert_eq "R4.4 — rien d'actif : null" "$(PA "$PH3" main 'j')" "null"
assert_eq "R4.5 — branche phase-9 inconnue : repli sur la mission running" "$(PA "$PH" feat/phase-9-y 'j.n')" "3"
assert_eq "R4.6 — numéro à zéro de tête (phase-02) : phase 2" "$(PA "$PH" feat/phase-02-x 'j.n')" "2"
A47="[{\"phases\":$PH,\"branche\":\"main\",\"current_phase\":\"1\",\"state\":{\"current_phase\":\"1\"}}]"; R47="$(Q phaseActive "$A47")"
assert_eq "R4.7 — un STATE qui pointe une autre phase n'a aucun effet" "$(G "$R47" 'j.n')" "3"
assert_eq "R4.8 — le résultat ne porte que key, n, nom, etat" "$(PA "$PH" main 'Object.keys(j).join(",")')" "key,n,nom,etat"

echo "=== R5 — aucun réseau ==="
: > "$WORK/git.log"
PATH="$WORK/bin:$PATH" node "$AUX/q.mjs" "$SCRIPTS" arbresGit "[\"$D\"]" > "$WORK/r5a.json" 2>/dev/null
PATH="$WORK/bin:$PATH" node "$AUX/q.mjs" "$SCRIPTS" retard "[{\"chemin\":\"$W\",\"base\":\"main\",\"commonDir\":\"$COM\",\"now\":\"NOW\"}]" > "$WORK/r5b.json" 2>/dev/null
PATH="$WORK/bin:$PATH" node "$AUX/q.mjs" "$SCRIPTS" brancheBase "[\"$D\"]" > "$WORK/r5c.json" 2>/dev/null
NLIG="$(grep -c . "$WORK/git.log")"; RESEAU="$(grep -cE '(^| )(fetch|pull|ls-remote|remote)( |$)' "$WORK/git.log")"
assert_eq "R5.1 — aucune sous-commande réseau de git (emballage vu à l'œuvre : au moins 5 appels)" "$([ "$NLIG" -ge 5 ] && echo vu || echo "aveugle:$NLIG")|$RESEAU" "vu|0"
PATH="$WORK/bin:$PATH" G_="$GIT_REEL" sh -c "git -C '$D' fetch origin >/dev/null 2>&1"
assert_eq "R5.2 — témoin positif : un fetch délibéré est journalisé" "$(grep -cE '(^| )fetch( |$)' "$WORK/git.log")" "1"
assert_eq "R5.3 — chaque appel git du module porte core.fsmonitor=false" "$(grep -v ' fetch ' "$WORK/git.log" | grep -vc 'core.fsmonitor=false')" "0"
export VF_SONDE_OUT="$WORK/sonde.out"
: > "$VF_SONDE_OUT"; rm -f "$VF_SONDE_OUT.charge"
node --import "$AUX/sonde.mjs" "$AUX/temoin-sortant.mjs" >/dev/null 2>&1
assert_eq "R5.4 — témoin positif : la sonde enregistre un fetch et une connexion délibérés" "$(cut -d' ' -f1 "$VF_SONDE_OUT" | sort | tr '\n' ',')" "fetch,net,"
: > "$VF_SONDE_OUT"; rm -f "$VF_SONDE_OUT.charge"
node --import "$AUX/sonde.mjs" "$AUX/q.mjs" "$SCRIPTS" retard "[{\"chemin\":\"$W\",\"base\":\"main\",\"commonDir\":\"$COM\",\"now\":\"NOW\"}]" > "$WORK/r5d.json" 2>/dev/null
assert_eq "R5.5 — retard : sonde chargée, 0 connexion sortante, résultat calculé" "$([ -s "$VF_SONDE_OUT.charge" ] && echo charge)|$(grep -c . "$VF_SONDE_OUT")|$(G "$(cat "$WORK/r5d.json")" 'j.main')" "charge|0|3"

echo "=== R6 — chaînes nettoyées ==="
ESC=$'\033'
assert_eq "R6.1 — nettoie retire l'échappement ANSI et le retour à la ligne" "$(G "$(node "$AUX/q.mjs" "$SCRIPTS" nettoie "[\"/tmp/a\\u001b[31mrouge\\nB\",80]" 2>/dev/null)" 'j')" "/tmp/a[31mrougeB"
assert_eq "R6.2 — nettoie borne à n caractères" "$(G "$(Q nettoie '["abcdefghij",4]')" 'j')" "abcd"
assert_eq "R6.3 — nettoie masque un jeton" "$(G "$(Q nettoie '["x ghp_abcdefghijklmnopqrstuvwxyz0123 y",80]')" 'j')" "x [masqué] y"
WE="$WORK/wt-${ESC}[31mpiege"; G_ -C "$D" worktree add -q --detach "$WE" main 2>/dev/null
RE="$(Q arbresGit "[\"$D\"]")"
assert_eq "R6.4 — un worktree au nom piégé est listé tel quel (le nettoyage est celui de l'émetteur)" "$(G "$RE" 'j.length')|$(G "$RE" 'j.some(a=>a.chemin.includes("\u001b"))')" "4|true"

echo "=== R7 — non-régression de who ==="
bash "$TESTS/test-cockpit-who.sh" > "$WORK/who.out" 2>&1; RC=$?
assert_eq "R7.1 — test-cockpit-who.sh rejoué : exit 0" "$RC" "0"

echo
echo "=== Résultats : $PASS PASS, $FAIL FAIL ==="
[ "$FAIL" -eq 0 ]
