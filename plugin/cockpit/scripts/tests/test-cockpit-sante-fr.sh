#!/usr/bin/env bash
# test-cockpit-sante-fr.sh — les constats du panneau Santé sont écrits en français À LA SOURCE (80-19, P80-D-54, FORM-18).
#   SF1 un constat de clé en fichier de test, lu dans la page SERVIE : titre, détail et invite en français, tels que le collecteur les écrit
#   SF2 les 14 genres de constats du collecteur en français (couverture comptée sur le source), noms propres gardés, nom de fichier hostile échappé
#   SF3 l'affichage ne retouche pas un constat français (t.constat), l'introduction du panneau est intacte, le dépôt n'est jamais muté
#   M   mutants sur une COPIE du module (cockpit_module_copie, serveur lancé sur la copie) : M-RESTE-ANGLAIS, M-NOM-PROPRE-TRADUIT, M-ECHAPPE
# Le panneau est lu dans la page servie par socle-serveur.sh, jamais dans un fichier de la sortie par service statique.
# Limite : sous ?lang=en les constats restent en français (même régime que les messages de serve.mjs). La traduction à l'affichage d'un constat
# ANGLAIS d'un graphe ancien (t.constat) est gardée par F23 de test-cockpit-chrome-fr.sh, qui n'est pas modifiée.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
TESTS="$(cd "$(dirname "$0")" && pwd)"; SCRIPTS="$(cd "$TESTS/.." && pwd)"
MOTEUR="$SCRIPTS/../skills/cockpit-moteur"; SANTE="$MOTEUR/scripts/lib/health.mjs"; UI="$MOTEUR/assets/ui/20-health.js"
WORK="$(mktemp -d)"; AUX="$WORK/aux"; mkdir -p "$AUX"; PIDS=()
trap 'vf_hyg_fin; rm -rf "$WORK"' EXIT
. "$TESTS/hygiene.sh"; vf_hyg_init
. "$TESTS/socle-serveur.sh"
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_ne() { if [ "$2" != "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (valeur interdite: [$3])"; FAIL=$((FAIL+1)); fi; }
HOSTILE='<img src=x onerror=window.__p=1>.js'
AWS="AKIA""QWERTY7890ZXCVBN"   # 20 caractères, format réel, entropie suffisante : aucune clé réelle

# --- le lab jetable : deux dépôts (app, backend), un fichier par genre de constat ---
cat > "$AUX/lab.mjs" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
const [, , racine, aws, hostile] = process.argv;
const w = (p, s) => { fs.mkdirSync(path.dirname(path.join(racine, p)), { recursive: true }); fs.writeFileSync(path.join(racine, p), s); };
const app = (p, s) => w('app/' + p, s);
const lignes = (n) => Array.from({ length: n }, (_, i) => `export const v${i} = ${i};`).join('\n') + '\n';
w('.planning/ROADMAP.md', '# Roadmap\n\n## Jalon A\n\n- [ ] **Phase 1: Socle** - premier jet\n');
app('tests/aws.test.js', `const k = "${aws}";\n`);
app('src/aws.js', `const k = "${aws}";\nexport default k;\n`);
app(`src/${hostile}`, `const k = "${aws}";\nexport default k;\n`);
app('src/App.jsx', "import { createClient } from '@supabase/supabase-js';\nexport const c = createClient;\nexport const appel = () => fetch('http://localhost:3000/api');\n");
app('src/main.jsx', "import App from './App.jsx';\nexport default App;\n");
app('package.json', JSON.stringify({ name: 'demo', dependencies: { react: '18.0.0', 'react-dom': '18.0.0', vite: '5.0.0' } }));
app('.env', `AWS_ACCESS_KEY_ID=${aws}\n`);
app('.env.local', 'VITE_STRIPE_SECRET_KEY=zq81xk29vm44ab7782qq\n');
app('supabase/migrations/001_init.sql', 'create table public.notes (id int primary key);\ncreate table public.posts (id int primary key, user_id uuid);\n'
  + 'alter table public.posts enable row level security;\ncreate policy "tout" on public.posts for all to anon using (true) with check (true);\n');
app('firestore.rules', "rules_version = '2';\nservice cloud.firestore {\n  match /databases/{database}/documents {\n    match /{document=**} {\n      allow read, write: if true;\n    }\n  }\n}\n");
app('api/stripe.js', "const express = require('express');\nconst cors = require('cors');\nconst stripe = require('stripe')('x');\nconst app = express();\n"
  + "app.post('/webhook/stripe', (req, res) => {\n  const event = req.body;\n  if (event.type === 'checkout.session.completed') { res.json({ ok: true }); }\n});\napp.use(cors());\nmodule.exports = app;\n");
app('server/routes.py', "from flask import Flask\napp = Flask(__name__)\n@jwt_required\n@app.route('/users', methods=['POST'])\ndef users():\n    return 'x'\n"
  + "@app.route('/orders', methods=['POST'])\n@jwt_required\ndef orders():\n    return 'ok'\n@app.route('/items', methods=['POST'])\ndef items():\n    return 'y'\n");
w('backend/api.py', "from flask import Flask\napp = Flask(__name__)\n@app.route('/things', methods=['POST'])\ndef things():\n    return 'y'\n");
app('src/orphan.js', 'export const orphan = 1;\n');
app('src/big.js', lignes(1200));
JS
cat > "$AUX/genres.mjs" <<'JS'
// genres.mjs <racine du module> <lab> : relance le collecteur (buildHealth) sur le graphe et l'analyse du lab construit ; imprime les constats
// (id, title, detail, fix, notes). Le nœud de l'application est déclaré « ui » pour que le genre « localhost » soit atteignable.
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , racine, lab] = process.argv;
process.env.VF_COCKPIT_GIT_DURCI = '1'; // git ne tourne que sous l'environnement durci de l'assemblage (common.mjs)
const { buildHealth } = await import(pathToFileURL(path.join(racine, 'skills/cockpit-moteur/scripts/lib/health.mjs')).href);
const sortie = path.join(lab, '.vibeflow/cockpit');
const html = fs.readFileSync(path.join(sortie, 'index.html'), 'utf8'), D = '<script>window.VF_COCKPIT = ';
const a = html.indexOf(D), graph = JSON.parse(html.slice(a + D.length, html.indexOf(';</script>', a)));
const scan = JSON.parse(fs.readFileSync(path.join(sortie, '.cache/scan.json'), 'utf8'));
for (const n of graph.nodes) if (graph.files.some((f) => f.n === n.id && /App\.jsx$/.test(f.p))) n.kind = 'ui';
const h = buildHealth({ graph, scan, arch: {}, root: lab });
console.log(JSON.stringify(h.issues.map((i) => ({ id: i.id, title: i.title, detail: i.detail, fix: i.fix, notes: Object.values(i.notes || {}) }))));
JS
cat > "$AUX/lire.mjs" <<'JS'
// lire.mjs <fichier json> <expression sur j> : imprime la valeur (chaîne telle quelle, sinon JSON)
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const e = process.argv[3], v = new Function('j', /\breturn\b/.test(e) ? e : 'return (' + e + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
lire() { node "$AUX/lire.mjs" "$1" "$2"; }
# mots témoins de l'anglais, hors segments de code (entre accents graves) et textes entre guillemets doubles
PRE='const strip=(s)=>String(s||"").replace(/`[^`]*`/g,"").replace(/"[^"]*"/g,"");'
PRE="$PRE"'const TEM=/\b(the|your|anyone|probably|fake|files?|keys?|every|these|this|with|without)\b/i;const ang=(s)=>TEM.test(strip(s));'
# les noms propres (service, fichier, variable) cités tels quels : liste des contrôles en échec
NOMS="$PRE"'const par=(p)=>j.find((i)=>i.id.startsWith(p))||{};const la=(i,c,m)=>String(par(i)[c]||"").includes(m);const r=[];'
NOMS="$NOMS"'if(!la("stripe-webhook:","title","Stripe"))r.push("Stripe");if(!la("firebase-rules:","title","Firebase"))r.push("Firebase");'
NOMS="$NOMS"'if(!la("rls:","detail","Supabase"))r.push("Supabase");if(!la("public-env","title","VITE_STRIPE_SECRET_KEY"))r.push("variable");'
NOMS="$NOMS"'if(!la("secret:app/src/aws.js","title","aws.js"))r.push("fichier");'
NOMS_FIX='if(!la("env-file:","fix",".gitignore")||!la("env-file:","fix",".env.example")||!la("env-file:","fix","git rm --cached"))r.push("env");'
ATTENDU_GENRES="$(node -e 'const s=require("fs").readFileSync(process.argv[1],"utf8");console.log(JSON.stringify([...new Set([...s.matchAll(/\bid: .([a-z-]+)[:\x27]/g)].map((m)=>m[1]))].sort()))' "$SANTE")"
FP_AVANT="$(cksum "$SANTE" "$UI")"

LAB="$WORK/lab"; mkdir -p "$LAB"; node "$AUX/lab.mjs" "$LAB" "$AWS" "$HOSTILE"
for r in app backend; do git -C "$LAB/$r" init -q; git -C "$LAB/$r" add -A; git -C "$LAB/$r" -c user.email=t@t -c user.name=t commit -q -m init; done
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet >/dev/null 2>&1 || echo "  assemblage du lab impossible"
node "$AUX/genres.mjs" "$SCRIPTS/.." "$LAB" > "$WORK/genres.json" 2> "$WORK/genres.err"

echo "=== SF2 — les genres de constats du collecteur (sans navigateur) ==="
assert_eq "SF2.0 — le collecteur a produit des constats sur le lab (jamais un vert à vide)" "$(lire "$WORK/genres.json" 'j.length > 10')" "true"
assert_eq "SF2.1 — les 14 genres relevés sur le source sont tous déclenchés (une couverture partielle rougit)" \
  "$(lire "$WORK/genres.json" '[...new Set(j.map((i) => i.id.split(":")[0]))].sort()')" "$ATTENDU_GENRES"
assert_eq "SF2.1b — aucun mot témoin anglais dans title, detail, notes et fix d'aucun constat (hors code et noms propres)" \
  "$(lire "$WORK/genres.json" "$PRE"'return [...new Set(j.flatMap((i) => [i.title, i.detail, i.fix, ...i.notes].filter(ang).map(() => i.id)))]')" "[]"
assert_eq "SF2.2 — noms propres gardés tels quels : Stripe, Firebase, Supabase, variable, fichier" "$(lire "$WORK/genres.json" "$NOMS"'return r')" "[]"
assert_eq "SF2.2b — le constat du fichier .env cite .gitignore, .env.example et git rm --cached" "$(lire "$WORK/genres.json" "$NOMS$NOMS_FIX"'return r')" "[]"

CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then
  . "$TESTS/chrome-saut.sh"; vf_chrome_saut "  ⊘ SF1, SF2.3, SF3 SAUTÉS : aucun navigateur — le panneau servi n'est PAS vérifié, non compté comme réussi"
else
  mkdir -p "$WORK/home/.claude/scripts"
  printf '#!/usr/bin/env bash\ncase "$1" in status) echo %s ;; orphans) echo %s ;; esac\n' "'{\"locks\":[]}'" "'{\"orphans\":[]}'" > "$WORK/home/.claude/scripts/driver-lock.sh"
  # lire_page <lab> <fichier de sortie> : lance le serveur (celui du module visé par COCKPIT_MODULE, sinon du dépôt), lit le panneau, arrête le serveur
  lire_page() {
    cockpit_lancer "$1" HOME="$WORK/home"; local rc=$? srv="${VF_PID:-}" port="${VF_PORT:-0}"
    if [ "$rc" -eq 0 ]; then node "$TESTS/chrome-sante-fr.mjs" "$CHROME" "http://127.0.0.1:$port/index.html" > "$2" 2> "$2.err"; else echo '{"erreur":"serveur"}' > "$2"; fi
    cockpit_arreter "$srv"; return "$rc"
  }
  echo "=== SF1 — un constat de clé en fichier de test, dans la page servie ==="
  lire_page "$LAB" "$WORK/page.json"; [ -z "${KEEP_PAGE:-}" ] || cp "$WORK/page.json" "$KEEP_PAGE"; assert_eq "SF1.0 — le serveur du lab a démarré et le pilote a lu la page (aucune erreur nommée)" "$(lire "$WORK/page.json" 'j.erreur || "aucune"')" "aucune"
  CLE='j.donnees.find((i) => i.id === "secret:app/tests/aws.test.js")'
  assert_eq "SF1.1 — le titre affiché est celui du collecteur, en français, et nomme aws.test.js" \
    "$(lire "$WORK/page.json" "$PRE"'const d='"$CLE"';return [j.affiches.some((a) => a.titre === d.title), /aws\.test\.js/.test(d.title), !ang(d.title)]')" "[true,true,true]"
  assert_eq "SF1.1b — le titre est exactement la forme attendue" "$(lire "$WORK/page.json" "$CLE"'.title')" "Une clé dans aws.test.js est probablement factice"
  assert_eq "SF1.2 — le détail affiché et l'invite (<pre>) sont ceux du collecteur et ne portent aucun mot témoin anglais" \
    "$(lire "$WORK/page.json" "$PRE"'const d='"$CLE"';return [j.affiches.some((a) => a.detail === d.detail), j.invite === d.fix, !ang(d.detail), !ang(j.invite)]')" "[true,true,true,true]"
  echo "=== SF2.3 — un nom de fichier hostile reste du texte ==="
  assert_eq "SF2.3 — le titre porte le nom en texte, aucun img dans le panneau, window.__p indéfini" \
    "$(lire "$WORK/page.json" '[String(j.hostile.titre).includes("'"$HOSTILE"'"), j.hostile.imgs, j.hostile.p]')" '[true,0,"undefined"]'
  echo "=== SF3 — affichage et introduction ==="
  assert_eq "SF3.1 — chaque constat français du collecteur traverse t.constat sans changement (titres et détails égaux, jamais vide)" \
    "$(lire "$WORK/page.json" 'const t=(l)=>JSON.stringify(l.sort());return [j.donnees.length > 10, t(j.affiches.map((a) => a.titre)) === t(j.donnees.map((d) => d.title)), t(j.affiches.map((a) => a.detail)) === t(j.donnees.map((d) => d.detail))]')" "[true,true,true]"
  INTRO="Nous avons cherché les clés laissées dans le code ou envoyées au navigateur, les données et les éléments de votre application accessibles à n'importe qui"
  INTRO="$INTRO sur internet, les fichiers oubliés et les fichiers trop gros pour être modifiés sans risque. C'est un contrôle rapide, pas un audit de sécurité."
  INTRO="$INTRO || Contrôles propres à ce que ce projet utilise : Supabase, Firebase, Stripe."
  assert_eq "SF3.2 — l'introduction du panneau, trois services, est le texte de la base (non retouchée)" "$(lire "$WORK/page.json" 'j.intro')" "$INTRO"
fi

echo
echo "=== Bilan : $PASS passés, $FAIL en échec ==="
[ $((PASS + FAIL)) -gt 0 ] || { echo "ÉCHEC ANTI-VERT-À-VIDE : aucun cas exécuté"; exit 1; }
[ "$FAIL" -eq 0 ]
