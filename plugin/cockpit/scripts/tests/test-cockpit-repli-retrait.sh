#!/usr/bin/env bash
# test-cockpit-repli-retrait.sh — le lecteur de repli de la régie est retiré (Phase 74, plan 74-10 ; TEMP-06, TEMP-12 ; P74-D-51, contrat P73-C2).
# La page n'a plus qu'un lecteur de transcript : la fiche. Ni `ouvrirRepli` (72-vf-regie-source.js) ni l'export `transcript` de window.__vfEquipeRendu (71-vf-equipe-rendu.js).
#   RP0 préalable : la fiche annule et ouvre pour `nom`, `ancre` et `rapport` (R5 et R5b de test-cockpit-equipe-retraits.sh) ; sans lui, retrait interdit
#   RP1 `ouvrirRepli` absent des modules d'interface   RP2 export `transcript` absent, aucun appelant   RP3 sans fiche, un `rapport` non annulé ne fait rien
#   RP6 recensement : seuls 74-vf-fiche.js et 74-vf-frise-fichiers.js nomment la route /api/vf/transcript dans leur code (un lecteur sous un autre nom que ouvrirRepli se verrait ici)
#   RP4 les témoins de la régie qui doivent rester verts le sont (test-cockpit-regie.sh)   RP5 témoin de remplacement : la ligne du fil de la fiche dit « × n » et l'heure,
#   une ligne sans heure lisible est écartée (ce que disaient T26.5, D8.6 et D8.8 du rendu retiré)
#   Mutants (copies du MODULE ; « MUTANT-ROUGE <nom> <sonde> » seulement quand la sonde a rougi) : M-REPLI-REVENU (RP1, RP3), M-EXPORT-REVENU (RP2), M-LECTEUR-AUTRE-NOM (RP6). REPLI_SANS_MUTANTS=1 les saute.
#   Chaque ligne : « ✅ PASS — <id> — <libellé> » ou « ❌ FAIL — <id> — <libellé> ». Navigateur absent : sondes de page SAUTÉES (dites). Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
HERE_T="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE_T/.." && pwd)"
UI="$SCRIPTS/../skills/cockpit-moteur/assets/ui"
WORK="$(mktemp -d)"
trap 'vf_hyg_fin; rm -rf "$WORK"' EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
. "$HERE_T/socle-serveur.sh"
WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"; export HOME="$WORK/home"
PIDS=(); T0=$(date +%s)
PASS=0; FAIL=0; SKIP=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
skip() { echo "  ⏭️  SAUTÉ — $1 ($2)"; SKIP=$((SKIP+1)); }
NODE="$(command -v node)"; export VF_CDP_ECHEANCE_MS="${VF_CDP_ECHEANCE_MS:-30000}"
CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
echo "navigateur : ${CHROME:-aucun (les sondes de page sont SAUTÉES)}"

# ---------- sondes statiques, sur un dossier ui/ (celui du module, ou celui d'une copie mutée) ----------
rp1() { local n; n="$(cat "$1"/*.js | grep -c 'ouvrirRepli' || true)"; echo "$n"; }
rp2() {
  local n t
  n="$(cat "$1"/*.js | grep -c '__vfEquipeRendu\.transcript' || true)"
  t="$("$NODE" -e 'const fs=require("fs"),vm=require("vm");const w={};vm.runInNewContext(fs.readFileSync(process.argv[1],"utf8"),{window:w,console});console.log(typeof w.__vfEquipeRendu.transcript)' "$1/71-vf-equipe-rendu.js" 2>&1 | tail -1)"
  echo "$t|appelants=$n"
}

# ---------- page : un `rapport` non annulé sur une copie du module SANS la fiche ----------
cat > "$AUX/pre.js" <<'JS'
window.__req = [];
{ const f0 = window.fetch.bind(window);
  window.fetch = (u, i) => { const url = typeof u === 'string' ? u : u.url;
    if (/^\/api\/vf\//.test(url)) window.__req.push(url);
    const rep = (corps, statut) => Promise.resolve(new Response(JSON.stringify(corps), { status: statut, headers: { 'content-type': 'application/json' } }));
    if (/^\/api\/vf\/frise(\?|$)/.test(url)) return rep({ erreur: 'indisponible' }, 503);
    if (/^\/api\/vf\/transcript\?/.test(url)) { const id = new URLSearchParams(url.split('?')[1]).get('id'); return rep({ schema: 'vibeflow/cockpit-transcript@2', id, fil: [], tronque: false, mandat: null }, 200); }
    return f0(u, i); }; }
JS
export VF_PRE="$AUX/pre.js"
cat > "$AUX/r.mjs" <<'JS'
export const ids = ['RP3'];
const voies = () => [];
const WHO = [
  { id: 'sess-1', kind: 'session', etat: 'au-repos', titre: 'Session principale', branch: 'feat/x', tree: '.', ageS: 300 },
  { id: 'mg-1', kind: 'subagent', role: 'vf-dev-manager', task: 'Piloter la phase 74', parent: 'sess-1', etat: 'actif', ageS: 10, branch: 'feat/x', tree: '.' },
  { id: 'wk-5', kind: 'subagent', role: 'vf-reviewer', task: 'Relire la jointure', parent: 'mg-1', etat: 'termine', ageS: 18000, branch: 'feat/x', tree: '.' },
];
const RAPPORT = '#vf-equipe li[data-vf-agent="wk-5"] .vf-rg-act button';
export default async function (h) {
  await h.monter({ voies, who: WHO, fil: () => ({}) });
  await h.ev(() => { window.__lus = []; window.__ouv = []; document.addEventListener('vf-agent:lu', (e) => window.__lus.push(e.detail && e.detail.id));
    document.addEventListener('vf-agent:ouvrir', (e) => window.__ouv.push([e.detail && e.detail.declencheur, e.defaultPrevented])); });
  await h.section('RP3', async () => {
    await h.attendre(`!!document.querySelector('${RAPPORT}')`, 'bouton « Lire le rapport » de la ligne terminée', 8000);
    const avant = await h.ev(() => ({ fiche: !!window.__vfFiche, panneau: (document.getElementById('panel') || {}).textContent || '' }));
    await h.ev((s) => document.querySelector(s).click(), RAPPORT);
    await h.ev(() => new Promise((ok) => setTimeout(ok, 900)));
    const r = await h.ev(() => ({ panneau: (document.getElementById('panel') || {}).textContent || '', req: window.__req.filter((u) => /transcript/.test(u)).length, lus: window.__lus.length,
      ouv: window.__ouv.map((x) => x.join(':')), surcouche: !!(window.VF_SURCOUCHES && typeof window.VF_SURCOUCHES.ouverte === 'function' && window.VF_SURCOUCHES.ouverte()),
      lecteur: document.querySelectorAll('#panel .sec .pt').length }));
    h.egal('RP3', 'sans fiche, un vf-agent:ouvrir « rapport » non annulé : l\'événement est émis, mais ni panneau, ni surcouche, ni requête de transcript, ni vf-agent:lu',
      [avant.fiche, r.ouv, r.panneau === avant.panneau, r.lecteur, r.surcouche, r.req, r.lus], [false, ['rapport:false'], true, 0, false, 0, 0]);
  });
}
JS

# ---------- lab et serveur ----------
LAB="$WORK/lab"; mkdir -p "$LAB/src" "$LAB/.planning/phases/01-x"
printf 'export const util = () => 1;\n' > "$LAB/src/util.js"
printf -- '- [x] **Phase 1: Socle** - premier jet\n' > "$LAB/.planning/ROADMAP.md"
printf -- '---\nstatus: executing\nmilestone: vibeflow-test\n---\n# State\n' > "$LAB/.planning/STATE.md"
printf '<objective>Faire le socle</objective>\n' > "$LAB/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$LAB/.planning/phases/01-x/01-01-SUMMARY.md"
git -C "$LAB" init -q -b main && git -C "$LAB" add -A && git -C "$LAB" -c user.email=t@t -c user.name=t commit -q -m init
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
demarrer() { COCKPIT_LOG="$WORK/serve-$1.out" cockpit_lancer "$LAB" HOME="$WORK/home" || true; }
sans_fiche() { rm -f "$1"/skills/cockpit-moteur/assets/ui/74-vf-fiche*.js; }
# rp3 <module> : joue RP3 sur un serveur lancé depuis cette copie du module (déjà privée de sa fiche) ; la sortie est dans $SORTIE
joue() {
  local port="$1" out line ok id lib ob
  out="$("$NODE" "$HERE_T/chrome-fiche.mjs" "$CHROME" "$AUX/r.mjs" "http://127.0.0.1:$port" 2>&1 | tail -1)"
  line="$("$NODE" -e 'let j; try { j = JSON.parse(process.argv[1]); } catch { process.exit(3); }
    if (!j.sondes) { console.log("ERR\t" + (j.erreur || "sortie illisible")); process.exit(0); }
    for (const s of j.sondes) console.log([s.ok ? "OK" : "KO", s.id, s.lib, s.obtenu].join("\t"));' "$out" 2>/dev/null)"
  SORTIE="$line"
  if [ -z "$line" ] || [ "${line%%$'\t'*}" = ERR ]; then
    echo "  ❌ FAIL — RP3 — scénario interrompu"; echo "     obtenu:  [${line:-${out:0:200}}]"; FAIL=$((FAIL+1)); return
  fi
  while IFS=$'\t' read -r ok id lib ob; do
    if [ "$ok" = OK ]; then echo "  ✅ PASS — $id — $lib"; PASS=$((PASS+1))
    else echo "  ❌ FAIL — $id — $lib"; echo "     obtenu:  [$ob]"; FAIL=$((FAIL+1)); fi
  done <<EOF
$line
EOF
}
sonde_rouge() { printf '%s\n' "$SORTIE" | awk -F'\t' -v s="$1" '$1 == "KO" && index($2, s) == 1 { f = 1 } END { exit f ? 0 : 1 }'; }

# ---------- RP0 : la fiche annule et ouvre pour les trois déclencheurs (preuve de 74-08, rejouée) ----------
echo "=== RP0 — préalable : l'annulation des déclencheurs nom, ancre et rapport par la fiche ==="
RET="$(RETRAITS_SANS_MUTANTS=1 bash "$HERE_T/test-cockpit-equipe-retraits.sh" 2>&1)"
cpt() { printf '%s\n' "$RET" | grep -c "$1" || true; }
RP0_OBT="nom=$(cpt '✅ PASS — R5b — nom (') rapport=$(cpt '✅ PASS — R5b — rapport (') ancre=$(cpt '✅ PASS — R5 — #r=n:ag') echecs=$(printf '%s\n' "$RET" | grep -cE '❌ FAIL — R5b? ' || true)"
assert_eq "RP0 — R5 (ancre) et R5b (nom clic, Entrée, Espace ; rapport) de test-cockpit-equipe-retraits.sh verts : « retrait interdit : annulation non prouvée » sinon" "$RP0_OBT" "nom=6 rapport=4 ancre=1 echecs=0"

# ---------- RP1, RP2 ----------
echo "=== RP1, RP2 — le lecteur de repli et l'export transcript ne sont plus dans les modules d'interface ==="
assert_eq "RP1 — aucune occurrence de ouvrirRepli dans ui/*.js (2 avant le retrait : définition et appel)" "$(rp1 "$UI")" "0"
assert_eq "RP2 — window.__vfEquipeRendu.transcript est undefined et aucun module ne l'appelle" "$(rp2 "$UI")" "undefined|appelants=0"

# ---------- RP6 : recensement des lecteurs de transcript (statique, code sans commentaires) ----------
rp6() { local r; r="$("$NODE" "$HERE_T/repli-recensement.mjs" "$1" 2>&1 | tail -1)"; "$NODE" -e 'try { const j = JSON.parse(process.argv[1]); console.log(j.temoin ? j.fichiers.join(",") : "temoin-rouge"); } catch { console.log("illisible"); }' "$r"; }
echo "=== RP6 — seuls la fiche et la lecture des fichiers de l'encart lisent /api/vf/transcript ==="
assert_eq "RP6 — les modules d'interface qui nomment /api/vf/transcript (code) : 74-vf-fiche.js seule (74-vf-frise-fichiers.js, de 74-06, n'est pas sur cette tête), et le motif sait trouver une lecture (témoin)" "$(rp6 "$UI")" "74-vf-fiche.js"

# ---------- RP5 : témoin de remplacement, le rendu du fil de la fiche ----------
cat > "$AUX/fil.cjs" <<'JS'
const fs = require('fs'), vm = require('vm');
const w = {}; vm.runInNewContext(fs.readFileSync(process.argv[2], 'utf8'), { window: w, console, Intl, Date });
const T = w.__vfFicheTexte;
const txt = (o) => (o.text !== undefined ? o.text : (o.children || []).map(txt).join(''));
const mk = (tag) => { const o = { tag, children: [], className: '' }; o.appendChild = (c) => { o.children.push(c); return c; }; o.setAttribute = () => {};
  Object.defineProperty(o, 'textContent', { get: () => txt(o), set: (v) => { o.children = [{ text: String(v) }]; } }); return o; };
const doc = { createElement: mk, createTextNode: (s) => ({ text: String(s) }) };
const li = T.ligneDom({ t: '2026-11-10T10:00:00.000Z', genre: 'outil', outil: 'Bash', verbe: 'lance une commande', cible: '', n: 14 }, doc, {});
const seul = T.ligneDom({ t: '2026-11-10T10:00:01.000Z', genre: 'outil', outil: 'Read', verbe: 'lit', cible: 'src/a.js' }, doc, {});
const lu = T.lireFil({ schema: 'vibeflow/cockpit-transcript@2', fil: [{ t: null, genre: 'message', texte: 'sans heure' }, { t: 'pas une date', genre: 'message', texte: 'illisible' }, { t: '2026-11-10T10:00:00.000Z', genre: 'message', texte: 'ok' }], mandat: '' });
const vide = T.lireFil({ schema: 'vibeflow/cockpit-transcript@2', fil: [], mandat: '' });
console.log([/ × 14$/.test(txt(li)), /^\d\d:\d\d:\d\d/.test(txt(li)), / × /.test(txt(seul)), lu.ok && lu.lignes.length === 1 && lu.ecartes === 2, vide.ok && vide.lignes.length === 0].join('|'));
JS
echo "=== RP5 — témoin de remplacement : le fil de la fiche dit « × n », l'heure ; une ligne sans heure lisible est écartée ==="
assert_eq "RP5 — ligne d'outil répétée : « × 14 » et une heure ; appel seul : pas de « × » ; deux lignes sans heure lisible écartées (2) ; fil vide sans exception" "$("$NODE" "$AUX/fil.cjs" "$UI/74-vf-fiche-texte.js" 2>&1 | tail -1)" "true|true|false|true|true"

# ---------- RP3 ----------
if [ -z "$CHROME" ]; then
  skip "RP3 (page)" "pas de navigateur"
else
  echo "=== RP3 — sans fiche, un rapport non annulé ne fait rien ==="
  MC="$(cockpit_module_copie "$WORK/mod-sf")"; sans_fiche "$MC"; export COCKPIT_MODULE="$MC"
  demarrer sf; PORT="$VF_PORT"; SRV="$VF_PID"
  assert_eq "S0 — contrôle positif : serveur de la copie sans fiche démarré" "$([ "$PORT" -gt 0 ] && echo serveur)" "serveur"
  joue "$PORT"
  cockpit_arreter "$SRV"; unset COCKPIT_MODULE
fi

# ---------- RP4 : les témoins de la régie qui restent verts ----------
echo "=== RP4 — les témoins de la 73 qui ne dépendent pas du repli restent verts (test-cockpit-regie.sh) ==="
REG="$(bash "$HERE_T/test-cockpit-regie.sh" RG0_socle RG0_ordre_page RG1_page RG11_page RG15_page RG16_page 2>&1)"
ligne() { printf '%s\n' "$REG" | grep -cE "✅ PASS — $1" || true; }
manque=""
for id in 'RG15\.1[ .]' 'RG15\.2 ' 'RG15\.3 ' 'RG15\.4 ' 'RG15\.5 ' 'RG15\.8 ' 'RG15\.9' 'RG1\.11 ' 'RG16\.1 ' 'RG0\.11 ' 'RG15\.6 — vf-agent:ouvrir annulé' 'RG15\.7 ' 'RG11\.10 — annulé'; do
  [ "$(ligne "$id")" -ge 1 ] || manque="$manque [$id]"
done
assert_eq "RP4 — une ligne PASS par témoin listé (RG15.1 à RG15.5, RG15.8, RG15.9, RG1.11, RG16.1, RG0.11 ; clauses restantes de RG15.6, RG15.7, RG11.10)" "${manque:-aucun manque}" "aucun manque"
assert_eq "RP4 — aucune ligne FAIL dans les sections jouées de la régie" "$(printf '%s\n' "$REG" | grep -c '❌ FAIL' || true)" "0"

# ---------- mutants ----------
if [ -n "$CHROME" ] && [ -z "${REPLI_SANS_MUTANTS:-}" ]; then
  echo "=== mutants (copies du module ; chacun rougit sa sonde) ==="
  if cockpit_module_muter M-REPLI-REVENU 72-vf-regie-source.js "s#if (declencheur === 'rapport') return;#if (declencheur === 'rapport') { ouvrirRepli(A, l.id, bouton, l.nom); return; }#;s#  function monter() {#  async function ouvrirRepli(A, id, ouvreur, nom) { emettre('vf-agent:lu', { id }, false); const P = document.getElementById('panel'); if (P) { const sec = document.createElement('div'), t = document.createElement('h2'); sec.className = 'sec'; t.className = 'pt'; t.textContent = nom; sec.appendChild(t); P.appendChild(sec); } }  function monter() {#"; then
    sans_fiche "$COCKPIT_MODULE"
    if [ "$(rp1 "$COCKPIT_MODULE/skills/cockpit-moteur/assets/ui")" != "0" ]; then echo "MUTANT-ROUGE M-REPLI-REVENU RP1"; PASS=$((PASS+1)); else echo "MUTANT-VERT M-REPLI-REVENU RP1"; echo "  ❌ FAIL — M-REPLI-REVENU — RP1 n'a pas rougi"; FAIL=$((FAIL+1)); fi
    demarrer mrepli
    if [ "${VF_PORT:-0}" -le 0 ]; then echo "  ❌ FAIL — M-REPLI-REVENU — serveur du mutant non démarré"; FAIL=$((FAIL+1)); else
      sp=$PASS; sf=$FAIL; joue "$VF_PORT" > "$WORK/mut-repli.out"; PASS=$sp; FAIL=$sf
      if sonde_rouge RP3; then echo "MUTANT-ROUGE M-REPLI-REVENU RP3"; PASS=$((PASS+1)); else echo "MUTANT-VERT M-REPLI-REVENU RP3"; echo "  ❌ FAIL — M-REPLI-REVENU — RP3 n'a pas rougi"; FAIL=$((FAIL+1)); fi
      cockpit_arreter "$VF_PID"
    fi
  else echo "  ❌ FAIL — M-REPLI-REVENU — mutation non posée (ancre absente)"; FAIL=$((FAIL+1)); fi
  unset COCKPIT_MODULE
  if cockpit_module_muter M-EXPORT-REVENU 71-vf-equipe-rendu.js "s#agentsDuNoeud, pied,#agentsDuNoeud, transcript: () => null, pied,#"; then
    if [ "$(rp2 "$COCKPIT_MODULE/skills/cockpit-moteur/assets/ui")" != "undefined|appelants=0" ]; then echo "MUTANT-ROUGE M-EXPORT-REVENU RP2"; PASS=$((PASS+1)); else echo "MUTANT-VERT M-EXPORT-REVENU RP2"; echo "  ❌ FAIL — M-EXPORT-REVENU — RP2 n'a pas rougi"; FAIL=$((FAIL+1)); fi
  else echo "  ❌ FAIL — M-EXPORT-REVENU — mutation non posée (ancre absente)"; FAIL=$((FAIL+1)); fi
  unset COCKPIT_MODULE
  # M-LECTEUR-AUTRE-NOM : un lecteur de transcript rendu sous un autre nom que ouvrirRepli (RP1 ne le voit pas, RP6 oui)
  if cockpit_module_muter M-LECTEUR-AUTRE-NOM 71-vf-equipe-rendu.js "s#agentsDuNoeud, pied,#agentsDuNoeud, lireFil: (id) => window.VF_ETAT.lireJson('/api/vf/transcript?id=' + encodeURIComponent(id)), pied,#"; then
    U="$COCKPIT_MODULE/skills/cockpit-moteur/assets/ui"
    if [ "$(rp1 "$U")" = "0" ] && [ "$(rp6 "$U")" != "74-vf-fiche.js" ]; then echo "MUTANT-ROUGE M-LECTEUR-AUTRE-NOM RP6 (RP1 resté vert : $(rp6 "$U"))"; PASS=$((PASS+1)); else echo "MUTANT-VERT M-LECTEUR-AUTRE-NOM RP6"; echo "  ❌ FAIL — M-LECTEUR-AUTRE-NOM — RP6 n'a pas rougi"; FAIL=$((FAIL+1)); fi
  else echo "  ❌ FAIL — M-LECTEUR-AUTRE-NOM — mutation non posée (ancre absente)"; FAIL=$((FAIL+1)); fi
  unset COCKPIT_MODULE
fi

echo
echo "durée : $(( $(date +%s) - T0 )) s"
echo "Résultat : $PASS réussis, $FAIL échecs, $SKIP sautés"
[ "$FAIL" -eq 0 ] && [ "$PASS" -gt 0 ]
