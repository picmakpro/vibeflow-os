#!/usr/bin/env bash
# test-cockpit-coin.sh — coin bas-droit, ligne d'état, repères de bord (80-05, FORM-10, FORM-12, P80-D-16/18/25/32/50), un vrai Chrome, sans réseau.
#   CN1 repères « N cartes par là » : compte, geste, ordre de Tab · CN2 bloc bas-droit, minicarte, hachure du tiroir Git, ligne d'état, sans terminal
#   CN3 feuille de détail (390 et 800 px), tactile, terminal ouvert, focus orphelin, mouvement réduit
#   Mutants (copie du module dans $WORK, jamais le module) : M-FREEAREA, M-COMPTE, M-TERMINAL.
#   CN_SCRIPTS = dossier de scripts à bâtir (rejeu sur la base). Sans navigateur : SUITE SAUTÉE (exit 0), jamais un vert à vide.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then
  . "$HERE_T/chrome-saut.sh"
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — le coin bas-droit NON vérifié, non compté comme réussi"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
assert_eq() {
  if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1))
  else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:600}]"; FAIL=$((FAIL+1)); fi
}
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('sortie illisible'); process.exit(0); }
if (j.erreur) { console.log('mesure indisponible : ' + j.erreur); process.exit(0); }
const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/mut.mjs" <<'JS'
import fs from 'node:fs'; const [, , f, a, b] = process.argv; const t = fs.readFileSync(f, 'utf8');
if (!t.includes(a) || t.split(a).length !== 2) { console.error('mutation impossible : motif absent ou multiple : ' + a); process.exit(1); }
fs.writeFileSync(f, t.replace(a, () => b));
JS
BRANCHE='vf/<img/src=x/onerror=window.__xss=1>/branche-tres-longue-pour-lellipse'
mklab() { # 70 notes dans un dossier (un niveau qui déborde), un module, une phase ; la branche est longue et hostile
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$L/plugin/mod/scripts" "$B/phases/01-socle" "$L/lots"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"
  printf '{"name":"mod","type":"skill","description":"Un module de test."}\n' > "$L/plugin/mod/module.json"; echo 1.0.0 > "$L/plugin/mod/VERSION"
  printf '# Module\n' > "$L/plugin/mod/README.md"; printf '#!/usr/bin/env bash\necho run\n' > "$L/plugin/mod/scripts/run.sh"
  for i in $(seq -w 1 70); do printf '# Note %s\n' "$i" > "$L/lots/n$i.md"; done
  printf '# Titre du projet\n' > "$B/PROJECT.md"
  printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n' > "$B/ROADMAP.md"
  printf -- '---\nfiles_modified: [plugin/mod/README.md]\n---\n<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  git -C "$L" init -q -b "$BRANCHE" && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
}
# build_serve <lab> <dossier de scripts> <dossier du moteur> [--terminal] -> PORT, SRV
build_serve() {
  local L="$1" O="$1/.vibeflow/cockpit" flag=(); [ "${4:-}" = "--terminal" ] && flag=(--terminal)
  node "$2/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
  rm -f "$O/.cache/server.json" "$O/.cache/terminal-amorce"; mkdir -p "$WORK/fauxbin" "$O/.cache"
  cp "$SCRIPTS/tests/temoins/fauxbin-claude/claude" "$WORK/fauxbin/claude"; chmod +x "$WORK/fauxbin/claude"
  [ -n "${flag[*]:-}" ] && (umask 077; node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" > "$O/.cache/terminal-amorce")
  ( cd "$L" && PATH="$WORK/fauxbin:$PATH" VF_COCKPIT_ENGINE_DIR="$3" VF_COCKPIT_SCRIPTS_DIR="$2" \
      exec node "$O/serve.mjs" --no-open ${flag[@]+"${flag[@]}"} --port "$(libre)" > "$WORK/serve.out" 2>&1 ) </dev/null >/dev/null 2>&1 &
  SRV=$!; PIDS+=($SRV)
  for _ in $(seq 1 300); do grep -q '"port"' "$O/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
  PORT="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$O/.cache/server.json','utf8')).port)" 2>/dev/null || echo 0)"
}
mesurer() { REAL_HOME="$REAL_HOME" node "${CN_PILOTE:-$HERE_T/chrome-coin.mjs}" "$CHROME" "http://127.0.0.1:$PORT" "$1" 2>"$WORK/mesure.err"; }
E() { printf '%s' "${2:-$R}" | node "$AUX/ev.mjs" "$1"; }
LAB="$WORK/lab"; mklab "$LAB"
SC_BASE="${CN_SCRIPTS:-$SCRIPTS}"; ln -s "$SC_BASE" "$WORK/scripts-hote"
build_serve "$LAB" "$WORK/scripts-hote" "$SC_BASE/../skills/cockpit-moteur"
assert_eq "CN0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"
if [ -n "${CN_SOLO:-}" ]; then # une seule mesure brute, hors suite : CN_SOLO=<mode>[:<sections>] (CN_PILOTE : un autre pilote)
  SOLO_S=""; case "$CN_SOLO" in *:*) SOLO_S="${CN_SOLO#*:}";; esac
  mesurer "${CN_SOLO%%:*}" "$SOLO_S"; vf_hyg_stop "$SRV"; vf_hyg_assert; exit 0
fi

echo "=== CN1 — repères « N cartes par là » ==="
R="$(mesurer cn1)"; [ -n "${SONDE:-}" ] && { printf '%s\n' "$R"; cat "$WORK/mesure.err"; }; [ -n "${KEEP:-}" ] && printf '%s\n' "$R" > "$WORK/cn1.json"
OK1='j.cn1.etats.every((e) => ["gauche", "droite", "haut", "bas"].every((b) => (e.reperes.find((r) => r.bord === b) || { n: 0 }).n === e.hors[b]))'
assert_eq "CN1.1 — niveau de 70 cartes : un repère au moins ; par bord, ajusté puis coupé puis écarté, compte = cartes ENTIÈREMENT hors champ" \
  "$(E "[j.cn1.etats.length === 4, j.cn1.etats.some((e) => e.reperes.length > 0),
    j.cn1.etats.some((e) => Object.values(e.hors).some((n) => n > 0)), $OK1]")" "[true,true,true,true]"
assert_eq "CN1.2 — clic sur le repère droit : la carte la plus proche est dans le champ, le compte diminue, zoom et sélection restent" \
  "$(E "(() => { const c = j.cn1.clic, a = c.avant, p = c.apres; if (!a || !p) return 'sans clic';
    return [a.hors.droite > 0, p.hors.droite < a.hors.droite, p.k === a.k, p.sel === a.sel, p.dedans]; })()")" "[true,true,true,true,true]"
NOM='/^\d+ cartes? hors champ (à gauche|à droite|en haut|en bas)\. Aller à la plus proche\.$/'
assert_eq "CN1.3 — Tab depuis la carte itinérante : un repère (button), nom « N cartes hors champ à <bord>. Aller à la plus proche. »" \
  "$(E "[j.cn1.tab.repere, $NOM.test(j.cn1.tab.nom || '')]")" "[true,true]"
assert_eq "CN1.9 — témoin : aucune section du pilote n'a échoué" "$(E 'Object.keys(j.erreurs).join()')" ""
echo "=== CN2 — bloc bas-droit, minicarte, hachure du tiroir Git, ligne d'état ==="
R="$(mesurer cn2)"; [ -n "${SONDE:-}" ] && { printf '%s\n' "$R"; cat "$WORK/mesure.err"; }; [ -n "${KEEP:-}" ] && printf '%s\n' "$R" > "$WORK/cn2.json"
assert_eq "CN2.1 — 1440 px : minicarte <= 144 x 96, bloc à 16 px de la zone libre (32 du panneau) et 8 px au-dessus de #ask ; fermé : 16 px du bord" \
  "$(E "(() => { const c = j.cn2.c21 || {}, k = c.coin, m = c.mini; if (!k || !m) return 'bloc absent';
    return [m.w > 0 && m.w <= 144 && m.h > 0 && m.h <= 96, Math.abs(c.panel.l - k.r - 32) <= 1, Math.abs(c.ask.t - 8 - k.b) <= 1,
      !!c.ferme && Math.abs(c.W - 16 - c.ferme.r) <= 1]; })()")" "[true,true,true,true]"
assert_eq "CN2.2 — clic au centre de la minicarte : le cadre du champ se recentre sur ce point, state.t.k inchangé" \
  "$(E "(() => { const c = j.cn2.c22; if (!c) return 'sans clic';
    return [Math.abs(c.visee[0] - c.centre[0]) < 1.5 && Math.abs(c.visee[1] - c.centre[1]) < 1.5, c.k[0] === c.k[1]]; })()")" "[true,true]"
assert_eq "CN2.3 — tiroir Git : freeArea().w et state.t identiques (PU-G-204), hachure (--text-3) sur la part couverte, cadre sans fond, nom" \
  "$(E "(() => { const c = j.cn2.c23; if (!c || !c.hf || !c.ho) return 'sans mesure';
    return [c.av.ouvert === false && c.ap.ouvert === true, c.av.w === c.ap.w, JSON.stringify(c.av.t) === JSON.stringify(c.ap.t), c.hf.affiche === false,
      c.ho.affiche, Math.abs(c.ho.part - c.attendu) < 0.005, Math.abs(c.ho.gauche - c.debut) < 0.005, c.ho.trait, c.ho.vide && c.hf.vide,
      /sous l'historique Git$/.test(c.ho.nom),
      !/historique Git/.test(c.hf.nom), /^Minicarte : \d+ cartes? visibles? sur \d+/.test(c.hf.nom)]; })()")" \
  "[true,true,true,true,true,true,true,true,true,true,true,true]"
NOMB='vf/<img/src=x/onerror=window.__xss=1>/branche-tres-longue-pour-lellipse'
assert_eq "CN2.4 — ligne d'état : branche entière en title et étiquette, ellipse au milieu (10 + … + 8), un seul role=status, heure qui suit vf-who" \
  "$(E "(() => { const c = j.cn2.c24; if (!c || !c.base) return 'sans mesure'; const b = c.base, n = '$NOMB';
    return [b.titre === n, b.nom.includes(n), b.vu === n.slice(0, 10) + '…' + n.slice(-8), b.status.length === 1 && /^Direct/.test(b.status[0]),
      b.mot === 'Direct',
      /^Mis à jour à \d\d:\d\d$/.test(b.heure), c.h1 === 'Mis à jour à 09:05', c.h2 === 'Mis à jour à 21:47']; })()")" \
  "[true,true,true,true,true,true,true,true]"
assert_eq "CN2.4b — direct coupé : « Reprise en cours, mise à jour à HH:MM » ; branche hostile (T-80-10) : aucun élément créé, aucun code exécuté" \
  "$(E "(() => { const c = j.cn2.c24; if (!c || !c.coupe) return 'sans mesure';
    return [c.coupe.mot, /^Reprise en cours, mise à jour à \d\d:\d\d$/.test(c.coupe.heure), c.base.xss.join()]; })()")" '["Direct coupé",true,"true,0"]'
assert_eq "CN2.5 — sans --terminal : aucun nœud vf-term dans #vf-coin, aucun mot « terminal », aucune commande (P71-D-02, P67-D-14)" \
  "$(E 'j.cn2.c25 ? [j.cn2.c25.term, j.cn2.c25.texte, j.cn2.c25.commandes] : "sans mesure"')" "[0,false,0]"
assert_eq "CN2.6 — 1440 et 1024 px, panneau et tiroir Git ouverts ou non : bloc, zoom, barre disjoints ; 900 px aucun bloc ; 1100 px tactile : état seul" \
  "$(E "(() => { const m = j.cn2.c26; if (!m || m.length !== 6) return 'sans mesure';
    return [m.slice(0, 4).map((x) => x.coin && x.ok).join(), m[4].coin, m[5].coin && !m[5].mini && m[5].etat]; })()")" '["true,true,true,true",null,true]'
assert_eq "CN2.9 — témoin : aucune section du pilote n'a échoué" "$(E 'Object.keys(j.erreurs).join()')" ""
echo "=== CN3 — feuille de détail (390 et 800 px), onglets, focus orphelin, mouvement réduit ==="
R="$(mesurer cn3)"; [ -n "${SONDE:-}" ] && { printf '%s\n' "$R"; cat "$WORK/mesure.err"; }; [ -n "${KEEP:-}" ] && printf '%s\n' "$R" > "$WORK/cn3.json"
for F in tactile moyen; do
  assert_eq "CN3.1 ($F) — feuille ouverte : aucun repère ; fermée : repères et zoom à 44 x 44 d'appui sans recouvrement, rien sur la carte sélectionnée" \
    "$(E "(() => { const f = j.cn3.f.$F; if (!f) return 'sans mesure'; const o = f.ouvert, c = f.ferme;
      return [o.ferme === false && o.n === 0, c.n > 0, c.appui, c.zones.every(([w, h]) => w >= 44 && h >= 44), c.libre, c.vue, c.couvre === 0,
        c.zoom === 3]; })()")" \
    "[true,true,true,true,true,true,true,true]"
done
assert_eq "CN3.2 — 390 px tactile : onglets de 36 de haut, zone d'appui de 44 (AUDC-X8) ; boutons de zoom à 44 x 44" \
  "$(E "(() => { const t = j.cn3.tabs; if (!t || !t.onglets) return 'sans mesure';
    return [t.onglets.length >= 3, t.onglets.every((o) => Math.abs(o.h - 36) <= 1), t.onglets.every((o) => o.haut && o.bas),
      t.zoom.length === 3 && t.zoom.every(([w, h]) => w >= 44 && h >= 44)]; })()")" \
  "[true,true,true,true]"
O4='j.cn3.orphelin'
assert_eq "CN3.4a — le repère droit épuisé par Entrée, focus dessus : il disparaît, le focus va à la carte qu'il vient d'amener (jamais body)" \
  "$(E "(() => { const a = $O4.a; if (!a || !a.apres) return 'sans mesure';
    return [a.focus, a.n >= 1, a.repere === false, a.apres.tag === 'g', a.apres.id === a.dernier]; })()")" "[true,true,true,true,true]"
assert_eq "CN3.4b — le repère bas tombe à 0 sans geste sur lui, focus dessus : le focus va au voisin précédent (haut), seul repère restant après lui" \
  "$(E "(() => { const b = $O4.b; if (!b || !b.apres) return 'sans mesure';
    return [b.focus, b.apres.tag, b.apres.bord, b.restants.includes('haut'), !b.restants.includes('bas')]; })()")" \
  '[true,"button","haut",true,true]'
assert_eq "CN3.4c — plus aucun repère : le focus va à la carte itinérante du canevas, jamais body" \
  "$(E "(() => { const c = $O4.c; if (!c || !c.apres) return 'sans mesure';
    return [c.focus, c.restants, c.apres.tag, c.apres.id !== null && c.apres.id === c.apres.itin]; })()")" '[true,0,"g",true]'
assert_eq "CN3.4d — un nouveau bord (haut) apparaît : le repère focalisé (droite) ne bouge pas, le focus y reste (jamais body)" \
  "$(E "(() => { const d = $O4.d; if (!d || !d.apres) return 'sans mesure'; return [d.focus, d.apres.tag, d.apres.bord, d.bords.includes('haut')]; })()")" \
  '[true,"button","droite",true]'
assert_eq "CN3.6 — 1000 et 1024 px, panneau et tiroir Git ouverts : repères gauche et droite présents et disjoints" \
  "$(E "(() => { const p = j.cn3.paires; if (!p || p.length !== 2) return 'sans mesure';
    return p.map((x) => [x.bords.includes('gauche') && x.bords.includes('droite') && x.deux, x.ok].join()); })()")" '["true,true","true,true"]'
assert_eq "CN3.5 — mouvement réduit : aucune animation active après un repère, un clic de minicarte et l'ouverture du tiroir Git" \
  "$(E "j.cn3.ro.media ? [j.cn3.ro.repere, j.cn3.ro.mini, j.cn3.ro.tiroir] : 'sans mesure'")" "[0,0,0]"
assert_eq "CN3.9 — témoin : aucune section du pilote n'a échoué" "$(E 'Object.keys(j.erreurs).join()')" ""
R="$(mesurer cn4)"; [ -n "${SONDE:-}" ] && { printf '%s\n' "$R"; cat "$WORK/mesure.err"; }; [ -n "${KEEP:-}" ] && printf '%s\n' "$R" > "$WORK/cn4.json"
assert_eq "CN4 — Projet en couloirs (1440 et 390 px, après « + » x 8 et un déplacement) : canevas masqué, ni minicarte ni repère, ligne d'état gardée" \
  "$(E "(() => { const c = j.cn4 && j.cn4['1440'], d = j.cn4 && j.cn4['390']; if (!c || !d) return 'sans mesure';
    return [c.cache, c.cartes > 0, !c.mini, c.reperes === 0, c.etat, d.cache, d.cartes > 0, !d.mini, d.reperes === 0]; })()")" \
  "[true,true,true,true,true,true,true,true,true]"
assert_eq "CN4.9 — témoin : aucune section du pilote n'a échoué" "$(E 'Object.keys(j.erreurs).join()')" ""
vf_hyg_stop "$SRV"
# le même lab lancé avec --terminal : la pastille « Terminal » et le tiroir du terminal (CN3.3)
LABT="$WORK/lab-term"; cp -R "$LAB" "$LABT"; build_serve "$LABT" "$WORK/scripts-hote" "$SC_BASE/../skills/cockpit-moteur" --terminal
assert_eq "CN3.0 — serveur du lab lancé avec --terminal démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"
R="$(mesurer term)"; [ -n "${SONDE:-}" ] && { printf '%s\n' "$R"; cat "$WORK/mesure.err"; }; [ -n "${KEEP:-}" ] && printf '%s\n' "$R" > "$WORK/term.json"
assert_eq "CN3.3a — 1440 px, tiroir du terminal ouvert : bloc et repères au-dessus du tiroir (rectangles disjoints)" \
  "$(E "(() => { const a = j.term.a; if (!a) return 'sans mesure';
    return [a.ok, a.noms.includes('#vf-coin'), a.noms.includes('.vf-term-tiroir'), a.noms.some((n) => n.includes('vf-repere'))]; })()")" "[true,true,true,true]"
assert_eq "CN3.3b — 1440 et 1024 px, tiroir fermé puis ouvert : pastille, bloc, zoom, barre, tiroir et repères disjoints deux à deux" \
  "$(E "(() => { const b = j.term.b; if (!b || b.length !== 2) return 'sans mesure';
    const rep = (n) => n.some((q) => q.includes('vf-repere')), tous = (n, l) => l.every((q) => n.includes(q));
    return b.map((x) => [x.ferme.ok, tous(x.ferme.noms, ['.vf-term-pastille', '#vf-coin', '#zoom', '#ask']), rep(x.ferme.noms),
      x.ouvert.ok, tous(x.ouvert.noms, ['#vf-coin', '.vf-term-tiroir']), rep(x.ouvert.noms)].join()); })()")" \
  '["true,true,true,true,true,true","true,true,true,true,true,true"]'
for F in tactile moyen; do
  assert_eq "CN3.3c ($F) — feuille de détail : chaque repère à 8 px au moins de la pastille « Terminal » et du zoom (toujours comptée)" \
    "$(E "(() => { const c = j.term.c.$F; if (!c) return 'sans mesure';
      return [c.pastille, c.n > 0, c.ecarts.every(([p, z]) => p >= 7.99 && (z === null || z >= 7.99))]; })()")" "[true,true,true]"
done
assert_eq "CN3.3z — témoin : aucune section du pilote n'a échoué" "$(E 'Object.keys(j.erreurs).join()')" ""
vf_hyg_stop "$SRV"

echo "=== Mutants (copie du module dans \$WORK) ==="
mutant() { # mutant <nom> <fichier relatif au moteur> <ancien> <nouveau> <mode> <sections> -> RM ; une mutation impossible compte comme un échec
  local M="$WORK/mod-$1" L="$WORK/lab-$1"; mkdir -p "$M/scripts" "$M/skills"
  cp "$SC_BASE"/*.mjs "$SC_BASE"/*.json "$M/scripts/"; cp -R "$SC_BASE/../skills/cockpit-moteur" "$M/skills/cockpit-moteur"; cp -R "$LAB" "$L"
  if ! node "$AUX/mut.mjs" "$M/skills/cockpit-moteur/$2" "$3" "$4"; then
    echo "  ❌ FAIL — $1 : mutation impossible"; FAIL=$((FAIL+1)); RM="{}"; return
  fi
  build_serve "$L" "$M/scripts" "$M/skills/cockpit-moteur"; RM="$(mesurer "$5" "$6")"; vf_hyg_stop "$SRV"; rm -rf "$L"
}
mutant M-FREEAREA assets/viewer.html "return { x: 16, y: top, w: Math.max(200, r.width - panelW - 32), h: Math.max(140, r.height - top - bottom) };" \
  "const tg = document.getElementById('vf-git-tiroir'), gw = tg && !tg.hidden ? tg.offsetWidth : 0;
  return { x: 16 + gw, y: top, w: Math.max(200, r.width - panelW - 32 - gw), h: Math.max(140, r.height - top - bottom) };" cn2 cn23
assert_eq "M-FREEAREA — le mutant rougit CN2.3 (freeArea() déduit le tiroir Git : sa largeur change à son ouverture) (témoin : le tiroir s'est bien ouvert)" \
  "$(E "[j.cn2.c23.av.w === j.cn2.c23.ap.w, j.cn2.c23.ap.ouvert]" "$RM")" "[false,true]"
mutant M-COMPTE assets/ui/02-vf-reperes.js "if (d[b] >= 0) {" "if (d[b] > -c.width * k / 2 - 1) {" cn1 cn1
assert_eq "M-COMPTE — le mutant rougit CN1.1 (carte coupée comptée hors champ) (témoins : des repères, quatre états, plus comptées que hors champ)" \
  "$(E "[$OK1, j.cn1.etats.some((e) => e.reperes.length > 0), j.cn1.etats.length,
    j.cn1.etats.flatMap((e) => e.reperes).reduce((a, r) => a + r.n, 0)
      > j.cn1.etats.flatMap((e) => Object.values(e.hors)).reduce((a, n) => a + n, 0)]" "$RM")" \
  "[false,true,4,true]"
mutant M-TERMINAL assets/ui/02-vf-ligne-etat.js "s.appendChild(ls);" \
  "s.appendChild(ls); const tm = document.createElement('span'); tm.className = 'vf-term-seg'; tm.textContent = 'Terminal'; ls.appendChild(tm);" cn2 cn25
assert_eq "M-TERMINAL — le mutant rougit CN2.5 (un segment « Terminal » ajouté sans --terminal) (témoin : le bloc existe)" \
  "$(E "[j.cn2.c25.term, j.cn2.c25.texte]" "$RM")" "[1,true]"
mutant M-ORPHELIN assets/ui/02-vf-reperes.js "if (fruit && S && S.focaliser(fruit)) return;" "if (fruit === 0) return;" cn3 cn34
assert_eq "M-ORPHELIN — le mutant rougit CN3.4a (le focus orphelin ne va plus à la carte amenée) (témoin : le repère droit a bien disparu)" \
  "$(E "[j.cn3.orphelin.a.apres.tag === 'g', j.cn3.orphelin.a.repere]" "$RM")" "[false,false]"
mutant M-ONGLETS assets/ui/02-vf-coin.js "inset: -4px 0;" "inset: 0;" cn3 cn32
assert_eq "M-ONGLETS — le mutant rougit CN3.2 (la zone d'appui des onglets retombe à 36 px) (témoin : l'onglet visuel reste à 36)" \
  "$(E "[j.cn3.tabs.onglets.every((o) => o.haut && o.bas), j.cn3.tabs.onglets.every((o) => Math.abs(o.h - 36) <= 1)]" "$RM")" "[false,true]"
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
