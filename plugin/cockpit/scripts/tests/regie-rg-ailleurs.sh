# regie-rg-ailleurs.sh — fragment du plan 73-02, SOURCÉ par test-cockpit-regie.sh (ne définit que des fonctions) :
# RG13_officiel (ailleurs() : sessions « vous attend » hors des arbres du lab, par nom de lab seulement, REGI-13) ·
# RG13_route (GET /api/vf/ailleurs : accès, lecture seule, aucune commande neuve par requête, aucun git hors du lab).
# Mutants nommés M-<NOM> : une assertion chacun, ancre vérifiée. Fixtures : noms de labs inventés, identifiants de session en UUID inventés,
# chemins construits à l'exécution sous $WORK ; faux `claude` et faux `git` dans $WORK/bin (journaux à chemin figé dans le script).

RG13_FX=""; RG13_SERVEUR=""

# rg13_fixtures : labs voisins, lab de fixture (dépôt git + un worktree au lien retour vérifié), binaires factices ; idempotente
rg13_fixtures() {
  [ -z "$RG13_FX" ] || return 0
  local w
  w="$(cd "$WORK" && pwd -P)"
  RG13_W="$w"; RG13_LAB="$w/lab"; RG13_POSTE="$w/poste"; RG13_BIN="$w/bin"; RG13_HOME="$w/home"
  RG13_MARK="$w/claude.log"; RG13_JSON="$w/agents.json"; RG13_RC="$w/claude.rc"; RG13_GITLOG="$w/git.log"
  mkdir -p "$RG13_POSTE/atelier/.claude/worktrees/w1" "$RG13_POSTE/forge" "$RG13_POSTE/menuiserie" "$w/lab-bis" "$RG13_BIN" \
    "$RG13_LAB/src" "$RG13_LAB/.planning/phases/01-socle" "$RG13_HOME"
  printf 'export const u = () => 1;\n' > "$RG13_LAB/src/util.js"
  printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n' > "$RG13_LAB/.planning/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$RG13_LAB/.planning/phases/01-socle/01-01-PLAN.md"; echo ok > "$RG13_LAB/.planning/phases/01-socle/01-01-SUMMARY.md"
  git -C "$RG13_LAB" init -q && git -C "$RG13_LAB" add -A && git -C "$RG13_LAB" -c user.email=t@t -c user.name=t commit -q -m init
  git -C "$RG13_LAB" worktree add -q "$RG13_LAB/.claude/worktrees/w1" -b w1
  RG13_REALGIT="$(command -v git)"
  printf '#!/bin/sh\necho "$@" >> "%s"\ncat "%s"\nexit "$(cat "%s" 2>/dev/null || echo 0)"\n' "$RG13_MARK" "$RG13_JSON" "$RG13_RC" > "$RG13_BIN/claude"
  printf '#!/bin/sh\nprintf "%%s|%%s\\n" "$(pwd -P)" "$*" >> "%s"\nexec "%s" "$@"\n' "$RG13_GITLOG" "$RG13_REALGIT" > "$RG13_BIN/git"
  chmod +x "$RG13_BIN/claude" "$RG13_BIN/git"
  : > "$RG13_MARK"; : > "$RG13_GITLOG"; echo 0 > "$RG13_RC"; echo '[]' > "$RG13_JSON"
  RG13_FX="{\"home\":\"$RG13_HOME\",\"lab\":\"$RG13_LAB\",\"poste\":\"$RG13_POSTE\",\"bin\":\"$RG13_BIN\",\"fichier\":\"$RG13_JSON\",\"rc\":\"$RG13_RC\",\"w\":\"$RG13_W\"}"
  export RG13_FX
}

# og <dossier de scripts> <corps JS> : importe vf-cockpit-etat-officiel.mjs (m) et vf-cockpit-arbres.mjs (a) de ce dossier, évalue le corps
# (X = fixtures, fs, path), imprime le résultat en JSON ; un échec du corps (ex. export absent) s'imprime « ERR … » : le témoin rougit
og() {
  local d="$1" body="$2"
  node --input-type=module -e 'import { pathToFileURL as U } from "node:url"; import fs from "node:fs"; import path from "node:path"; const X = JSON.parse(process.env.RG13_FX); process.env.PATH = X.bin + path.delimiter + process.env.PATH; process.env.HOME = X.home; const F = Object.getPrototypeOf(async () => {}).constructor; let r; try { const m = await import(U(path.join(process.argv[1], "vf-cockpit-etat-officiel.mjs")).href); const a = await import(U(path.join(process.argv[1], "vf-cockpit-arbres.mjs")).href); r = await new F("m", "a", "X", "fs", "path", process.argv[2])(m, a, X, fs, path); } catch (e) { r = "ERR " + e.message; } console.log(typeof r === "string" ? r : JSON.stringify(r)); process.exit(0);' "$d" "$body" 2>/dev/null
}

# préambule des corps : S(cwd, état) = une entrée de `claude agents --json` ; lire(liste, rc, brut) = lecture officielle sur le faux claude ; al(opts) = ailleurs() avec les racines du lab
OGP='const P = X.poste, ID = (i) => "3f2c9a10-5b7e-4c1d-9a2e-0d4f6b8c1e" + String(10 + i).padStart(2, "0"); let k = 0;
  const S = (cwd, st, extra) => ({ sessionId: ID(k++), kind: "interactive", pid: 4000 + k, cwd, ...st, ...extra }); const BL = { state: "blocked" }, WA = { status: "waiting" };
  const lire = async (l, rc = 0, brut) => { fs.writeFileSync(X.fichier, brut !== undefined ? brut : JSON.stringify(l)); fs.writeFileSync(X.rc, String(rc)); await m.rafraichir({ home: X.home, cwd: X.lab }); };
  const al = (o) => m.ailleurs(X.home, { racines: a.arbresGit(X.lab).map((t) => t.chemin), homeDir: X.home, ...o });'

rg13_cas_attend() { og "$1" "$OGP"' await lire([S(P + "/atelier", BL)]); return al();'; }
rg13_cas_etats() { og "$1" "$OGP"' await lire([S(P + "/atelier", WA)]); const a1 = al(); await lire([S(P + "/atelier", { state: "working" }), S(P + "/atelier", { status: "idle" }), S(P + "/atelier", { state: "done" }), S(P + "/atelier", { status: "busy" })]); return [a1, al()];'; }
rg13_cas_lab() { og "$1" "$OGP"' await lire([S(X.lab, BL), S(X.lab + "/src", BL), S(X.lab + "/.claude/worktrees/w1", WA)]); const dedans = al(); await lire([S(X.w + "/lab-bis", BL)]); return [dedans, al()];'; }
rg13_cas_noms() { og "$1" "$OGP"' await lire([S(P + "/menuiserie", BL), S(P + "/forge", WA), S(P + "/atelier/.claude/worktrees/w1", BL), S(P + "/atelier", BL)]); return al();'; }
rg13_cas_sortie() { og "$1" "$OGP"' const t = "TITRE-SECRET-ZED"; await lire([S(P + "/atelier", BL, { name: t, title: t, summary: t })]); const r = al(), j = JSON.stringify(r); return [r.map((x) => Object.keys(x).join(",")), j.includes(P), j.includes(ID(0)), j.includes(t)];'; }
rg13_cas_nettoie() { og "$1" "$OGP"' await lire([S(P + "/at‮el\u0007ier", BL)]); const r1 = al(); await lire([S(P + "/" + "q".repeat(90), BL)]); return [r1, al()[0].lab.length];'; }
rg13_cas_perso() { og "$1" "$OGP"' await lire([S(X.home, BL), S(path.dirname(X.home), BL), S("/seul", BL)]); return al();'; }
rg13_cas_nul() { og "$1" "$OGP"' const r = []; const lisible = [S(P + "/atelier", BL)];
  await lire(lisible, 1); r.push(al()); await lire(lisible, 0, "{pas du json"); r.push(al()); await lire([S(42, BL)]); r.push(al());
  await lire(lisible); r.push(al({ now: Date.now() + 61000 })); r.push(al({ racines: undefined })); r.push(m.ailleurs("home-jamais-lu", { racines: [X.lab] })); return r;'; }

rg_RG13_officiel() {
  rg13_fixtures
  assert_eq "RG13.0 — témoin positif : une session « blocked » d'un lab voisin « atelier » donne [{ lab: atelier, n: 1 }]" "$(rg13_cas_attend "$SCRIPTS")" '[{"lab":"atelier","n":1}]'
  assert_eq "RG13.1 — status « waiting » compte ; « working », « idle », « done », « busy » ne comptent pas" "$(rg13_cas_etats "$SCRIPTS")" '[[{"lab":"atelier","n":1}],[]]'
  assert_eq "RG13.2 — dans le lab, son sous-dossier et son worktree (lien vérifié) : rien ; un lab dont le nom commence par celui du lab : compté (segment entier)" "$(rg13_cas_lab "$SCRIPTS")" '[[],[{"lab":"lab-bis","n":1}]]'
  assert_eq "RG13.3 — worktree d'un autre lab = ce lab ; deux sessions du même lab : n = 2 ; trois labs triés par n décroissant puis nom" "$(rg13_cas_noms "$SCRIPTS")" '[{"lab":"atelier","n":2},{"lab":"forge","n":1},{"lab":"menuiserie","n":1}]'
  assert_eq "RG13.4 — la sortie n'a que lab et n : ni dossier, ni identifiant de session, ni titre" "$(rg13_cas_sortie "$SCRIPTS")" '[["lab,n"],false,false,false]'
  assert_eq "RG13.4b — caractères de contrôle et de sens d'écriture retirés du nom ; nom de 90 caractères borné à 40" "$(rg13_cas_nettoie "$SCRIPTS")" '[[{"lab":"atelier","n":1}],40]'
  assert_eq "RG13.5 — dossier personnel, un de ses ancêtres, chemin d'un seul segment : « un autre dossier »" "$(rg13_cas_perso "$SCRIPTS")" '[{"lab":"un autre dossier","n":3}]'
  assert_eq "RG13.6 — commande en échec, JSON illisible, entrée en attente sans cwd, lecture de plus de 60 s, racines absentes, aucune lecture : null (jamais 0)" "$(rg13_cas_nul "$SCRIPTS")" '[null,null,null,null,null,null]'
  rg_mutant AILLEURS-CWD "la sortie garde le dossier" "$SCRIPTS" vf-cockpit-etat-officiel.mjs 'const l = lignes.get(lab) || { lab, n: 0 };' 'const l = lignes.get(lab) || { lab, n: 0, cwd };' rg13_cas_sortie '[["lab,n"],false,false,false]'
  rg_mutant AILLEURS-TITRE "le nom du lab porte l'identifiant de session" "$SCRIPTS" vf-cockpit-etat-officiel.mjs 'out.push(e.cwd);' 'out.push(e.cwd + "#" + e.sessionId);' rg13_cas_sortie '[["lab,n"],false,false,false]'
  rg_mutant AILLEURS-SOUS-ARBRE "égalité stricte au lieu de « sous la racine »" "$SCRIPTS" vf-cockpit-etat-officiel.mjs 'rs.some((r) => dessous(r, d))' 'rs.some((r) => r === d)' rg13_cas_lab '[[],[{"lab":"lab-bis","n":1}]]'
  rg_mutant AILLEURS-HOME "repli du dossier personnel retiré" "$SCRIPTS" vf-cockpit-etat-officiel.mjs 'if (dessous(base, hd)) return AUTRE;' 'if (false) return AUTRE;' rg13_cas_perso '[{"lab":"un autre dossier","n":3}]'
}

# ---------- RG13_route : le serveur réel ----------
rg13_serveur_init() {
  [ -z "$RG13_SERVEUR" ] || return 0
  rg13_fixtures
  . "$TESTS_DIR/hygiene.sh"; PIDS=(); vf_hyg_init
  . "$TESTS_DIR/socle-serveur.sh"
  trap 'vf_hyg_fin; rm -rf "$WORK"' EXIT   # le filet de la suite arrête aussi les serveurs si la section s'interrompt
  node "$SCRIPTS/vf-cockpit-build.mjs" "$RG13_LAB" --quiet > "$WORK/rg13-build.out" 2>&1 || cat "$WORK/rg13-build.out"
  cat > "$AUX/rg13req.mjs" <<'JS'
// rg13req.mjs <port> <méthode> <chemin> [jeton] : imprime le code HTTP puis le corps
import http from 'node:http';
const [, , port, method, p, token] = process.argv;
const headers = { Host: `127.0.0.1:${port}` }; if (token) headers['x-vf-cockpit-token'] = token;
const r = http.request({ host: '127.0.0.1', port: Number(port), path: p, method, headers, agent: false }, (res) => { let b = ''; res.on('data', (c) => (b += c)); res.on('end', () => { console.log(res.statusCode); console.log(b); process.exit(0); }); });
r.on('error', () => { console.log('000'); process.exit(1); }); r.end();
JS
  RG13_SERVEUR=1
}
rg13_n() { wc -l < "$1" | tr -d ' '; }
rg13_get() { cockpit_get /api/vf/ailleurs > "$WORK/rg13-body" 2>/dev/null; RG13_CODE="$VF_CODE"; }
rg13_liste() { rg13_get; [ "$RG13_CODE" = 200 ] && [[ "$(cat "$WORK/rg13-body")" == *'"lab"'* ]]; }

# rg13_run <fichier résultat> : lance le serveur (COCKPIT_MODULE s'il est posé), joue le scénario, écrit des lignes « clé=valeur », arrête le serveur.
# À appeler dans le shell courant (jamais dans $(…)).
rg13_run() {
  local res="$1" i avant_c avant_g liste="non" lab_n
  rg13_serveur_init
  P="$RG13_POSTE"
  printf '[{"sessionId":"3f2c9a10-5b7e-4c1d-9a2e-0d4f6b8c1e10","kind":"interactive","pid":4001,"cwd":"%s","state":"blocked"},{"sessionId":"3f2c9a10-5b7e-4c1d-9a2e-0d4f6b8c1e11","kind":"interactive","pid":4002,"cwd":"%s","status":"waiting"},{"sessionId":"3f2c9a10-5b7e-4c1d-9a2e-0d4f6b8c1e12","kind":"interactive","pid":4003,"cwd":"%s","state":"working"}]' "$P/atelier" "$RG13_LAB/src" "$P/forge" > "$RG13_JSON"
  echo 0 > "$RG13_RC"; : > "$RG13_MARK"; : > "$RG13_GITLOG"
  COCKPIT_SORTIE="$RG13_LAB/.vibeflow/cockpit" cockpit_lancer "$RG13_LAB" PATH="$RG13_BIN:$PATH"
  if [ "${VF_PORT:-0}" = 0 ]; then echo "lancement=ko" > "$res"; return 0; fi
  attendre 15 test -s "$RG13_MARK" || true   # la lecture officielle du serveur a eu lieu (le faux claude a été appelé)
  attendre 8 rg13_liste && liste="oui"
  rg13_get
  { echo "lancement=ok"; echo "code=$RG13_CODE"
    echo "schema=$(G "$WORK/rg13-body" 'j.schema' 2>/dev/null)"; echo "liste=$(G "$WORK/rg13-body" 'j.ailleurs' 2>/dev/null)"; echo "rendue=$liste"; } > "$res"
  node "$AUX/rg13req.mjs" "$VF_PORT" POST /api/vf/ailleurs "$VF_JETON" | sed -n 1p | sed 's/^/post=/' >> "$res"
  node "$AUX/rg13req.mjs" "$VF_PORT" GET /api/vf/ailleurs | sed -n 1p | sed 's/^/sanstoken=/' >> "$res"
  avant_c="$(rg13_n "$RG13_MARK")"; avant_g="$(rg13_n "$RG13_GITLOG")"
  for i in 1 2 3 4 5 6 7 8 9 10; do rg13_get; done
  sleep 1
  echo "dclaude=$(( $(rg13_n "$RG13_MARK") - avant_c ))" >> "$res"; echo "dgit=$(( $(rg13_n "$RG13_GITLOG") - avant_g ))" >> "$res"
  echo "gitlab=$(grep -c "^$RG13_LAB" "$RG13_GITLOG")" >> "$res"
  echo "gitdehors=$(grep -v "^$RG13_LAB" "$RG13_GITLOG" | grep -c .)|$(grep -c "$RG13_POSTE" "$RG13_GITLOG")" >> "$res"
  cockpit_arreter
  return 0
}
rg13_ch() { sed -n "s/^$2=//p" "$1" | head -1; }   # rg13_ch <fichier> <clé>

# mutation d'un module copié : rg13_muter <nom> <fichier> <expr sed> ; exporte COCKPIT_MODULE (code 1 si la copie n'a pas changé)
rg13_mutant_serveur() { # rg13_mutant_serveur <NOM> <libellé> <fichier> <expr sed> <clé> <valeur saine> [seconde expr sed sur le serveur]
  local nom="$1" lib="$2" fic="$3" expr="$4" cle="$5" sain="$6" r="$WORK/rg13-mut-$1.res" got
  if ! cockpit_module_muter "RG13-$nom" "$fic" "$expr"; then assert_eq "M-$nom — $lib (ancre)" "ancre absente" "muté"; unset COCKPIT_MODULE; return 0; fi
  if [ -n "${7:-}" ]; then
    local s="$COCKPIT_MODULE/scripts/vf-cockpit-routes.mjs"
    sed "$7" "$s" > "$s.mut" && ! cmp -s "$s" "$s.mut" && mv "$s.mut" "$s" || { assert_eq "M-$nom — $lib (seconde ancre)" "ancre absente" "muté"; unset COCKPIT_MODULE; return 0; }
  fi
  rg13_run "$r"
  got="$(rg13_ch "$r" "$cle")"
  unset COCKPIT_MODULE
  if [ -n "$got" ] && [ "$got" != "$sain" ]; then echo "  ✅ PASS — M-$nom — $lib (mutant tué : $cle=$got, sain $sain)"; PASS=$((PASS+1))
  else echo "  ❌ FAIL — M-$nom — $lib (mutant survivant ou serveur muet)"; echo "     attendu: [différent de $sain]"; echo "     obtenu:  [$got]"; FAIL=$((FAIL+1)); fi
}

rg_RG13_route() {
  local r d
  rg13_serveur_init
  r="$WORK/rg13-sain.res"; rg13_run "$r"
  assert_eq "RG13.10 — GET avec jeton : 200, schéma vibeflow/cockpit-ailleurs@1, ailleurs = [{ atelier, 1 }] après la lecture officielle du serveur" "$(rg13_ch "$r" code)|$(rg13_ch "$r" schema)|$(rg13_ch "$r" liste)" '200|vibeflow/cockpit-ailleurs@1|[{"lab":"atelier","n":1}]'
  assert_eq "RG13.11 — POST avec jeton : 405 (lecture seule)" "$(rg13_ch "$r" post)" "405"
  assert_eq "RG13.12 — GET sans jeton : 403" "$(rg13_ch "$r" sanstoken)" "403"
  assert_eq "RG13.13 — précondition (la route a rendu la liste) puis dix GET : le journal du faux claude et celui du faux git ne gagnent aucune ligne" "$(rg13_ch "$r" rendue)|$(rg13_ch "$r" dclaude)|$(rg13_ch "$r" dgit)" "oui|0|0"
  assert_eq "RG13.14 — témoin positif (au moins un git dans un arbre du lab) puis aucun git hors du lab ni dans un autre lab pendant tout le scénario" "$([ "$(rg13_ch "$r" gitlab)" -gt 0 ] 2>/dev/null && echo oui || echo non)|$(rg13_ch "$r" gitdehors)" "oui|0|0"
  rg13_mutant_serveur AILLEURS-GIT "un git lancé dans le dossier de la session" vf-cockpit-etat-officiel.mjs 's@const lab = nomDuLab(d, hd);@const lab = (execFile("git", ["-C", d, "status"], () => {}), nomDuLab(d, hd));@' gitdehors "0|0"
  rg13_mutant_serveur ROUTE-PAR-REQUETE "la route relance la lecture officielle" vf-cockpit-server.mjs 's@ailleurs: ailleurs(os.homedir(), @ailleurs: (import("./vf-cockpit-etat-officiel.mjs").then((m) => m.rafraichir({ home: os.homedir(), cwd: c.root })), ailleurs)(os.homedir(), @' dclaude 0
  rg13_mutant_serveur ROUTE-SANS-JETON "contrôle de jeton neutralisé (portail de serve.mjs et accès gardé)" serve.mjs 's@(!sameToken(given, token) && !VF?.jetonValide(given))@false@' sanstoken 403 's@if (!jetonValide(h\[entete\])) return { ok: false, code: 403 };@@'
  vf_hyg_assert
}
