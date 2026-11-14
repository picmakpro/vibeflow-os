# regie-rg-gouvernance.sh — fragment du plan 73-01, SOURCÉ par test-cockpit-regie.sh (ne définit que des fonctions) :
# RG0_socle (autotest du lanceur et de ses outils) · RG4_donnees (À vous : vérification humaine, REGI-04) · RG5_donnees (impact, REGI-05) ·
# RG7_donnees (fenêtre de stall à source unique, REGI-07) · RG10_donnees (« attend ses agents », REGI-10). Mutants nommés M-<NOM> : une assertion chacun.
# Fixtures : noms inventés, identifiants de session en UUID inventés, aucun chemin de poste (les chemins sont construits à l'exécution).

# gv <dossier de scripts> <corps JS> [args…] : importe vf-cockpit-regie-donnees.mjs de ce dossier (m), évalue le corps (A = args, fs), imprime le résultat en JSON ;
# module absent ou illisible : sortie vide (le témoin rougit)
gv() {
  local d="$1" body="$2"; shift 2
  node --input-type=module -e 'import { pathToFileURL } from "node:url"; import fs from "node:fs"; const m = await import(pathToFileURL(process.argv[1]).href); const F = Object.getPrototypeOf(async () => {}).constructor; let r; try { r = await new F("m", "A", "fs", process.argv[2])(m, process.argv.slice(3), fs); } catch (e) { r = "ERR " + e.message; } console.log(typeof r === "string" ? r : JSON.stringify(r));' "$d/vf-cockpit-regie-donnees.mjs" "$body" "$@" 2>/dev/null
}

# ---------- RG0 — autotest du socle ----------
rg_RG0_socle() {
  local out rc d p0 f0 dd
  out="$(VF_REGIE_FRAGMENTS= bash "$TESTS_DIR/test-cockpit-regie.sh" RGX 2>&1)"; rc=$?
  assert_eq "RG0.1 — section demandée inconnue : sortie 1 et « section inconnue »" "$rc|$([[ "$out" == *"section inconnue : RGX"* ]] && echo oui || echo non)" "1|oui"

  d="$WORK/frag-vide"; mkdir -p "$d"; printf 'rg_RG9_vide() { :; }\n' > "$d/regie-rg-vide.sh"
  out="$(VF_REGIE_FRAGMENTS="$d" bash "$TESTS_DIR/test-cockpit-regie.sh" RG9 2>&1)"; rc=$?
  assert_eq "RG0.2 — fragment sans assertion : « 0 PASS » et sortie 1" "$rc|$([[ "$out" == *"Résultats : 0 PASS"* ]] && echo oui || echo non)" "1|oui"

  dd="$WORK/rg0-mut"; mkdir -p "$dd"; printf 'abab\n' > "$dd/x.txt"
  p0=$PASS; f0=$FAIL
  out="$(rg_mut zz "$dd" x.txt 'ABSENT' 'y')"; rc=$?
  local out2 rc2; out2="$(rg_mut zz "$dd" x.txt 'ab' 'y')"; rc2=$?
  rg_mutant ZZ "ancre absente" "$dd" x.txt 'ABSENT' 'y' false sain > "$WORK/rg0-mutant.out" 2>&1
  local delta=$((FAIL-f0)); PASS=$p0; FAIL=$f0
  assert_eq "RG0.3 — ancre absente ou ambiguë : message, code 1, et l'assertion du mutant rougit" "$out|$rc|$out2|$rc2|$delta|$(grep -c '❌ FAIL — M-ZZ' "$WORK/rg0-mutant.out")" "ancre absente|1|ancre ambiguë|1|1|1"

  printf 'process.exit(3);\n' > "$AUX/h3.mjs"
  printf 'console.log("  ✅ PASS — HX.1 — témoin");\n' > "$AUX/h0.mjs"
  p0=$PASS; f0=$FAIL
  rg_node "$AUX/h3.mjs" > "$WORK/rg0-h3.out" 2>&1; local dF=$((FAIL-f0)); FAIL=$f0
  rg_node "$AUX/h0.mjs" > "$WORK/rg0-h0.out" 2>&1; local dP=$((PASS-p0)); PASS=$p0; FAIL=$f0
  assert_eq "RG0.4 — harnais qui sort 3 sans ligne FAIL : un FAIL « code 3 » ; une ligne PASS du harnais est comptée" "$dF|$(grep -c 'harnais h3.mjs : code 3' "$WORK/rg0-h3.out")|$dP" "1|1|1"

  d="$WORK/frag-dix"; mkdir -p "$d"; printf 'rg_RG10_x() { assert_eq "ZZ.1 — sentinelle" a a; }\n' > "$d/regie-rg-dix.sh"
  local o1 o2 o3
  o1="$(VF_REGIE_FRAGMENTS="$d" bash "$TESTS_DIR/test-cockpit-regie.sh" RG1 2>&1)"
  o2="$(VF_REGIE_FRAGMENTS="$d" bash "$TESTS_DIR/test-cockpit-regie.sh" RG10 2>&1)"
  o3="$(VF_REGIE_FRAGMENTS="$d" bash "$TESTS_DIR/test-cockpit-regie.sh" RG10_x 2>&1)"
  assert_eq "RG0.5 — RG1 ne retient pas RG10_x ; RG10 et RG10_x le retiennent" "$([[ "$o1" == *"section inconnue : RG1"* && "$o1" != *"ZZ.1"* ]] && echo a)|$([[ "$o2" == *"✅ PASS — ZZ.1"* ]] && echo b)|$([[ "$o3" == *"✅ PASS — ZZ.1"* ]] && echo c)" "a|b|c"
}

# ---------- RG4 — phases à vérification humaine (REGI-04, A1) ----------
HUM='const mk = (o) => new Map([["w|73", { key: "w|73", n: "73", ws: "w", ...o }]]); const F = () => ["73-VERIFICATION.md", "73-01-PLAN.md"]; const L = (t) => () => t; const OK = "---\nstatus: human_needed\n---\ncorps\n";'
rg4_entete() { gv "$1" "$HUM"'
  const r = (t) => m.phasesHumaines({ phases: mk({}), lire: L(t), fichiers: F }).length;
  const big = "---\nstatus: human_needed\n---\n" + "x".repeat(2 << 20);
  const loin = "---\n" + "k: v\n".repeat(100) + "status: human_needed\n---\n";
  return [r("---\nstatus: passed\n---\nstatus: human_needed\n"), r("---\nphase: 73\n---\nstatus: human_needed\n"), r("---\nstatus: human_needed\nsuite sans fin\n"), r(big), r(loin)];'; }
rg4_cochee() { gv "$1" "$HUM"' return m.phasesHumaines({ phases: mk({ done: true }), lire: L(OK), fichiers: F });'; }
rg_RG4_donnees() {
  assert_eq "RG4.1 — phase non cochée, en-tête human_needed : une entrée { phase, ws, cle }" "$(gv "$SCRIPTS" "$HUM"' return m.phasesHumaines({ phases: mk({}), lire: L(OK), fichiers: F });')" '[{"phase":"73","ws":"w","cle":"w|73"}]'
  assert_eq "RG4.2 — A1 : même dossier, phase cochée au ROADMAP : aucune entrée" "$(rg4_cochee "$SCRIPTS")" '[]'
  assert_eq "RG4.2b — phase archivée : aucune entrée" "$(gv "$SCRIPTS" "$HUM"' return m.phasesHumaines({ phases: mk({ archive: true }), lire: L(OK), fichiers: F });')" '[]'
  assert_eq "RG4.3 — corps après le second ---, en-tête sans statut, bloc non fermé, tête seule lue sur 2 Mio, statut au-delà de 40 lignes" "$(rg4_entete "$SCRIPTS")" '[0,0,0,1,0]'
  rg_mutant HUMAN-NEEDED-COCHEE "filtre « cochée » retiré" "$SCRIPTS" vf-cockpit-regie-donnees.mjs 'if (p.done || p.archive) continue;' 'if (p.archive) continue;' rg4_cochee '[]'
  rg_mutant ENTETE-CORPS "statut cherché hors de l'en-tête" "$SCRIPTS" vf-cockpit-regie-donnees.mjs 'const bloc = lignes.slice(1, fin);' 'const bloc = lignes;' rg4_entete '[0,0,0,1,0]'
}

# ---------- RG5 — impact : aval, détention, impact retenu (REGI-05) ----------
DAG1='const N = (id, deps, status) => ({ id, deps, status }); const dag1 = [N("a", [], "ready"), N("b", ["a"], "ready"), N("c", ["b"], "done"), N("d", ["a"], "blocked")];'
rg5_aval() { gv "$1" "$DAG1"' return [m.aval(dag1, "a"), m.aval(dag1, "c"), m.aval(dag1, "inconnu")];'; }
RET='const ph = new Map([["w|73", { key: "w|73", n: "73", ws: "w" }]]); const N = (id, deps, status) => ({ id, deps, status }); const dag = { name: "MISSION-73", ws: "w", wsDeclare: "w", phase: "73", nodes: [N("n1", [], "done"), N("n2", ["n1"], "done"), N("n3", ["n2"], "ready"), N("n4", ["n3"], "ready"), N("n5", ["n4"], "blocked"), N("n6", [], "running")] }; const det = { ws: "w", phase: "73" };'
rg5_retient() { gv "$1" "$RET"' return [m.retientDe({ rattachement: null, detention: det }, { dags: [dag], phases: ph }), m.retientDe({ rattachement: null, detention: det }, { dags: [], phases: ph }), m.retientDe({ rattachement: null, detention: null }, { dags: [dag], phases: ph }), m.retientDe({ rattachement: { dag: "MISSION-73", noeud: "n3" }, detention: null }, { dags: [dag], phases: ph })];'; }
rg_RG5_donnees() {
  local sid="3f2c9a10-5b7e-4c1d-9a2e-0d4f6b8c1e77"
  assert_eq "RG5.1 — DAG a→b→c, a→d, c terminé : aval(a)=2, aval(c)=0, nœud inconnu 0" "$(rg5_aval "$SCRIPTS")" '[2,0,0]'
  assert_eq "RG5.2 — cycle, identifiant dupliqué, deps scalaire, __proto__/constructor, entrées hostiles : aucune exception, résultats finis" "$(gv "$SCRIPTS" 'const N = (id, deps, status) => ({ id, deps, status });
    return [m.aval([N("a", ["b"], "ready"), N("b", ["a"], "ready")], "a"), m.aval([N("a", [], "ready"), N("a", [], "ready")], "a"), m.aval([N("a", [], "ready"), N("x", "a", "ready")], "a"),
      m.aval([N("__proto__", ["constructor"], "ready"), N("constructor", ["__proto__"], "ready")], "__proto__"), m.aval(null, "a"), m.aval("abc", "a"), m.aval([null, 5, {}], "a"), m.aval([N("a", [], "ready")], undefined), m.aval([N("a", [], "ready")], {}), m.restants([null, N("a", [], "done"), N("b", [], "ready"), N("__proto__", [], "ready")])];')" '[1,0,0,1,0,0,0,0,0,2]'
  assert_eq "RG5.3 — detention : listée → { ws, phase } ; non listée, verrou absent, ws hors grammaire → null" "$(gv "$SCRIPTS" 'const L = { locks: [{ present: true, ws: "w", phase: "72", session_ids: ["s-1"] }, { present: true, ws: "w", phase: "73", session_ids: [A[0], "s-2"] }, { present: false, ws: "w", phase: "74", session_ids: ["s-3"] }] };
    return [m.detention(A[0], L), m.detention("autre", L), m.detention("s-3", L), m.detention("s-9", { locks: [{ present: true, ws: "../x", phase: "73", session_ids: ["s-9"] }] }), m.detention(A[0], L.locks)];' "$sid")" '[{"ws":"w","phase":"73"},null,null,null,{"ws":"w","phase":"73"}]'
  assert_eq "RG5.4 — retientDe : détention + DAG → mission (4) ; sans DAG → null ; sans détention → null ; rattachement → nœuds (2)" "$(rg5_retient "$SCRIPTS")" '[{"n":4,"portee":"mission"},null,null,{"n":2,"portee":"noeuds"}]'
  rg_mutant IMPACT-TERMINES "aval compte aussi les nœuds terminés" "$SCRIPTS" vf-cockpit-regie-donnees.mjs "return [...vus].filter((id) => statut.get(id) !== 'done').length;" 'return vus.size;' rg5_aval '[2,0,0]'
  rg_mutant IMPACT-DEVINE "retientDe rend les restants du premier DAG sans détention" "$SCRIPTS" vf-cockpit-regie-donnees.mjs 'return null; // impact inconnu : jamais deviné' "return liste(dags).length ? { n: restants(liste(dags)[0].nodes), portee: 'mission' } : null;" rg5_retient '[{"n":4,"portee":"mission"},null,null,{"n":2,"portee":"noeuds"}]'
}

# ---------- RG7 — fenêtre de stall à source unique (REGI-07, P73-D-09, P73-D-31) ----------
rg7_variante() { gv "$1" 'return m.fenetreStall({ env: {}, texteScript: fs.readFileSync(A[0], "utf8") });' "$2"; }
rg7_600() { rg7_variante "$1" "$RG7_V600"; }
rg7_3b() { rg7_variante "$1" "$RG7_V3B"; }
rg7_env() { gv "$1" 'return m.fenetreStall({ env: { VF_STALL_WINDOW: "600" }, texteScript: fs.readFileSync(A[0], "utf8") });' "$RG7_GARDE"; }
rg_RG7_donnees() {
  local ligne='STALL_WINDOW="${VF_STALL_WINDOW:-900}"' s0 s1 s2 occ
  RG7_GARDE="$SCRIPTS/../../conductor/scripts/check-guard-health.sh"
  RG7_V600="$(rg_copie "$RG7_GARDE")"; RG7_VABS="$(rg_copie "$RG7_GARDE")"; RG7_V3B="$(rg_copie "$RG7_GARDE")"
  s0="$(FROM="$ligne" TO='STALL_WINDOW="${VF_STALL_WINDOW:-600}"' node "$AUX/mutsub.mjs" "$RG7_V600")"
  s1="$(FROM="$ligne" TO='' node "$AUX/mutsub.mjs" "$RG7_VABS")"
  s2="$(FROM="$ligne" TO=$'# STALL_WINDOW="${VF_STALL_WINDOW:-900}"\n  STALL_WINDOW="${VF_STALL_WINDOW:-900}"' node "$AUX/mutsub.mjs" "$RG7_V3B")"
  occ="$(grep -c -F -x "$ligne" "$RG7_GARDE")"
  assert_eq "RG7.0 — fixtures : la ligne source est présente une fois dans le vrai script, les trois variantes sont posées" "$occ|$s0|$s1|$s2" "1|muté|muté|muté"
  assert_eq "RG7.1 — le vrai check-guard-health.sh du dépôt donne 900 (valeur mesurée à HEAD)" "$(gv "$SCRIPTS" 'return m.fenetreStall({ env: {}, texteScript: fs.readFileSync(A[0], "utf8") });' "$RG7_GARDE")" '900'
  assert_eq "RG7.2 — variante dont le défaut vaut 600 sur sa seule ligne d'affectation : 600 (la fenêtre suit la ligne)" "$(rg7_600 "$SCRIPTS")" '600'
  assert_eq "RG7.3 — variante sans cette ligne : null (jamais un 900 en dur)" "$(rg7_variante "$SCRIPTS" "$RG7_VABS")" 'null'
  assert_eq "RG7.3b — variante dont la seule occurrence est en commentaire ou indentée : null" "$(rg7_3b "$SCRIPTS")" 'null'
  # variantes de script : la sonde rouge est le témoin lui-même, rejoué sous le nom du mutant
  assert_eq "M-STALL-LIGNE — défaut de la ligne source altéré dans la copie : la fenêtre servie suit la ligne (600, pas 900)" "$(rg7_600 "$SCRIPTS")" '600'
  assert_eq "M-STALL-ABSENT — ligne source retirée : aucun nœud marqué, jamais de 900 en dur" "$(rg7_variante "$SCRIPTS" "$RG7_VABS")" 'null'
  assert_eq "RG7.4 — VF_STALL_WINDOW=600 → 600 ; abc, 0, -5, vide → la ligne du script" "$(gv "$SCRIPTS" 'const t = fs.readFileSync(A[0], "utf8"); return ["600", "abc", "0", "-5", ""].map((v) => m.fenetreStall({ env: { VF_STALL_WINDOW: v }, texteScript: t }));' "$RG7_GARDE")" '[600,900,900,900,900]'
  # RG7.5 : scriptGarde — voisin du driver-lock.sh résolu hors du lab observé
  local a="$WORK/g75/a" b="$WORK/g75/b" lab="$WORK/g75/lab"
  mkdir -p "$a" "$b" "$lab/.claude/scripts"
  : > "$a/driver-lock.sh"; : > "$a/check-guard-health.sh"; : > "$b/driver-lock.sh"
  : > "$lab/.claude/scripts/driver-lock.sh"; : > "$lab/.claude/scripts/check-guard-health.sh"
  assert_eq "RG7.5 — scriptGarde : voisin dans un dossier explicite ; dossier sans ce script, script posé sous le lab observé, rien : null" "$(gv "$SCRIPTS" 'const [a, b, lab, vide] = A; const s = (o) => { const r = m.scriptGarde(o); return r === null ? null : r.slice(a.length); };
    return [s({ scriptsDir: a, labRoot: lab, home: vide }), s({ scriptsDir: b, labRoot: lab, home: vide }), s({ scriptsDir: vide + "/absent", labRoot: lab, home: lab }), s({ labRoot: lab, home: vide })];' "$a" "$b" "$lab" "$WORK/g75/vide")" '["/check-guard-health.sh",null,null,null]'
  rg_mutant STALL-DUR "extraction qui rend toujours 900" "$SCRIPTS" vf-cockpit-regie-donnees.mjs 'return m && Number(m[1]) > 0 ? Number(m[1]) : null;' 'return 900;' rg7_600 '600'
  rg_mutant STALL-ENV "variable d'environnement ignorée" "$SCRIPTS" vf-cockpit-regie-donnees.mjs 'if (typeof e === '"'string'"' && /^\d+$/.test(e) && Number(e) > 0) return Number(e);' '' rg7_env '600'
  rg_mutant STALL-ANCRE "ancrage de début de ligne retiré" "$SCRIPTS" vf-cockpit-regie-donnees.mjs '/^STALL_WINDOW=' '/STALL_WINDOW=' rg7_3b 'null'
}

# ---------- RG10 — « attend ses agents (N) » (REGI-10, P73-D-12, A12) ----------
rg10_ligne() { printf '{"type":"system","subtype":"turn_duration","pendingBackgroundAgentCount":%s}\n' "$1"; }
rg10_apres() { gv "$1" 'return m.attendAgents(A[0]);' "$RG10_T2"; }
rg_RG10_donnees() {
  local d="$WORK/g10" a='{"type":"assistant","message":{"content":[{"type":"text","text":"suite"}]}}' u='{"type":"user","message":{"content":"mandat"}}'
  mkdir -p "$d"
  { printf '%s\n%s\n' "$u" "$a"; rg10_ligne 3; } > "$d/t1.jsonl"
  { rg10_ligne 3; printf '%s\n' "$a"; } > "$d/t2.jsonl"
  { rg10_ligne 3; printf '{"type":"system","subtype":"autre"}\n'; } > "$d/t3.jsonl"
  rg10_ligne 0 > "$d/v0.jsonl"; rg10_ligne -2 > "$d/vneg.jsonl"; rg10_ligne 1.5 > "$d/vfrac.jsonl"; rg10_ligne 5000 > "$d/vmax.jsonl"
  printf '{"type":"system","subtype":"turn_duration"}\n' > "$d/vabs.jsonl"
  RG10_T2="$d/t2.jsonl"
  assert_eq "RG10.1 — dernière ligne turn_duration avec pendingBackgroundAgentCount 3 : 3" "$(gv "$SCRIPTS" 'return m.attendAgents(A[0]);' "$d/t1.jsonl")" '3'
  assert_eq "RG10.2 — une ligne assistant écrite après la turn_duration : 0" "$(rg10_apres "$SCRIPTS")" '0'
  assert_eq "RG10.3 — A12 : une ligne system d'un autre sous-type après : 0" "$(gv "$SCRIPTS" 'return m.attendAgents(A[0]);' "$d/t3.jsonl")" '0'
  assert_eq "RG10.4 — valeur 0, négative, non entière, 5000 : 0, 0, 0, 999" "$(gv "$SCRIPTS" 'return A.map((f) => m.attendAgents(f));' "$d/v0.jsonl" "$d/vneg.jsonl" "$d/vfrac.jsonl" "$d/vmax.jsonl")" '[0,0,0,999]'
  assert_eq "RG10.5 — champ absent : 0 ; fichier absent : 0" "$(gv "$SCRIPTS" 'return A.map((f) => m.attendAgents(f));' "$d/vabs.jsonl" "$d/absent.jsonl")" '[0,0]'
  rg_mutant ATTEND-REMONTE "le prédicat laisse passer les autres lignes et remonte à une ancienne turn_duration" "$SCRIPTS" vf-cockpit-regie-donnees.mjs 'return { n: 0 }; // toute autre ligne : la dernière écriture décide' 'return null;' rg10_apres '0'
}
