#!/usr/bin/env bash
# test-cockpit-moteur-carte.sh — témoins de comportement du moteur de carte (lot 1, étape M4 : panneau, clavier, fenêtres), sans réseau.
#   K1 fenêtre « Exporter une copie » : focus dedans, Échap et clic sur le fond la ferment, focus rendu (PU-G-014)
#   K2 noms accessibles : flèche d'envoi « Ask », copie du chemin « Copy path » (PU-G-018)
#   K3 « détail technique » ne change ni les statistiques ni les libellés de la fiche d'un fichier (PU-G-058)
#   K4 fiche d'un document : « Mentions » et une phrase d'explication, jamais « Depends on » ni « calls » (PU-G-072)
#   K5 encart des noms générés : la commande réelle et un bouton qui la copie (PU-G-074)
#   K6 lignes du panneau atteignables au Tab (PU-G-174) · K7 Échap hors du canevas ne remonte pas d'un niveau (PU-G-175)
#   K8 anneau de focus de l'en-tête à toutes les largeurs (PU-G-013) · K9 repérage sans halo, 700 ms au plus
#   K10 bulle de réponse : hauteur limitée, refermée au changement de vue (PU-G-149) · K11 « Retour » revient à la carte d'où partait la question (PU-G-148)
#   K14 panneau de détail fermé par défaut à 768 px, ouvert à 1 024 px (PU-G-045)
#   K15 colonnes d'une vue de partie : carte sans lien dans la colonne du milieu, titres lisibles (PU-G-040) · K16 vue de réponse remise à zéro (PU-G-059, PU-G-143, PU-G-144)
#   K17 compteurs et homonymes du travail récent (PU-G-054, PU-G-049)
#   K18 l'infobulle ne revient pas après une navigation par la recherche, sur Code (1 440 et 768 px) et Projet (PU-G-035, recette du 2026-11-08)
#   K12 nœud d'une mission : état réel en glyphe et mot, plus de « 0 » ni de « 0 lines » (PU-G-105) · K13 onglet Équipe à 390 px : une seule colonne (PU-G-176)
# Un chargement de page unique (chrome-moteur-carte.mjs, un Chrome, profil jetable) ; les assertions se lisent ensuite sur sa sortie JSON. Lab construit par la suite, dans mktemp.
# Sans navigateur : la suite se déclare SAUTÉE (exit 0, message explicite) — jamais un vert à vide. Exit 0 si tout passe.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$SCRIPTS/../skills/cockpit-moteur"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then echo "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — le moteur de carte NON vérifié, non compté comme réussi"; exit 0; fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:600}]"; FAIL=$((FAIL+1)); fi; }
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('sortie illisible'); process.exit(0); }
if (j.erreur) { console.log('mesure indisponible : ' + j.erreur); process.exit(0); }
const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
# session d'équipe : un manager et neuf workers actifs (de quoi faire une grille de cartes), à la forme réelle mesurée par test-cockpit-equipe.sh
cat > "$AUX/mk-agents.mjs" <<'JS'
import fs from 'node:fs'; import path from 'node:path';
const [, , home, lab, sid] = process.argv; const now = Date.now();
const dir = path.join(home, '.claude', 'projects', '-lab'); const sub = path.join(dir, sid, 'subagents'); fs.mkdirSync(sub, { recursive: true });
const iso = (ms) => new Date(ms).toISOString(); const base = (o) => ({ cwd: lab, sessionId: sid, gitBranch: 'main', version: '2.1.317', ...o });
const put = (f, lignes) => fs.writeFileSync(f, lignes.map((l) => JSON.stringify(l)).join('\n') + '\n');
put(path.join(dir, sid + '.jsonl'), [base({ type: 'user', timestamp: iso(now - 600000), message: { content: 'salut' } }), base({ type: 'assistant', timestamp: iso(now - 5000), message: { content: [{ type: 'tool_use', name: 'Bash', input: { command: 'echo bonjour' } }] } })]);
const agents = [{ id: 'mgr1', d: 1, role: 'vf-dev-manager' }]; for (let i = 1; i <= 9; i++) agents.push({ id: 'act' + i, d: 2, parent: 'mgr1', role: 'vf-coder' });
for (const a of agents) {
  const meta = { agentType: a.role, isBuiltIn: false, launchedWithDefaults: false, description: 'tâche synthétique ' + a.id, toolUseId: 'toolu_' + a.id, spawnDepth: a.d, requestShape: 'background', requestNonInteractive: true };
  if (a.d >= 2) meta.parentAgentId = a.parent;
  fs.writeFileSync(path.join(sub, `agent-${a.id}.meta.json`), JSON.stringify(meta));
  put(path.join(sub, `agent-${a.id}.jsonl`), [base({ type: 'user', isSidechain: true, agentId: a.id, parentUuid: null, timestamp: iso(now - 300000), message: { role: 'user', content: 'mandat de ' + a.id } }), base({ type: 'assistant', isSidechain: true, agentId: a.id, timestamp: iso(now - 4000), message: { role: 'assistant', content: [{ type: 'tool_use', id: 'toolu_x' + a.id, name: 'Read', input: { file_path: lab + '/README.md' } }] } })]);
}
JS
mklab() { # mklab <dir> : un module avec un document et deux scripts qui s'appellent, une phase, un plan de bataille (un nœud fait, un en cours)
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$L/plugin/mod/scripts" "$B/phases/01-socle" "$B/missions"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"
  printf '{"name":"mod","type":"skill","description":"Un module de test."}\n' > "$L/plugin/mod/module.json"; echo 1.0.0 > "$L/plugin/mod/VERSION"
  printf '# Module\n\nLancer `run.sh`, puis `check.sh`.\n' > "$L/plugin/mod/README.md"
  printf '#!/usr/bin/env bash\necho run\n' > "$L/plugin/mod/scripts/run.sh"
  printf '#!/usr/bin/env bash\nsource ./run.sh\necho check\n' > "$L/plugin/mod/scripts/check.sh"
  printf '#!/usr/bin/env bash\necho seul\n' > "$L/plugin/mod/scripts/seul.sh" # aucun lien : sa carte forme un composant à part (PU-G-040)
  printf '# Scripts\n\nLes scripts du module.\n' > "$L/plugin/mod/scripts/README.md" # homonyme du README du module (PU-G-049)
  mkdir -p "$L/lots"; for i in $(seq -w 1 30); do printf '# Note %s\n' "$i" > "$L/lots/n$i.md"; done # de quoi remplir un tableau au-delà de son plafond de 24 cartes (PU-G-054)
  printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - second jet\n\n### Phase 1: Socle\n**Depends on**: Nothing (first phase)\n\n### Phase 2: Suite\n**Depends on**: Phase 1\n' > "$B/ROADMAP.md" # phase 2 : la dépendance du panneau de phase (PU-G-100)
  printf -- '---\nfiles_modified: [plugin/mod/README.md, plugin/mod/scripts/README.md]\n---\n<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"; echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  printf '{"nodes":[{"id":"a","step":"première étape","stage":"","deps":[],"scope":["src/**"],"status":"done"},{"id":"b","step":"seconde étape","stage":"","deps":["a"],"scope":["src/**"],"status":"running"},{"id":"c","step":"troisième étape","stage":"","deps":["b"],"scope":["src/**"],"status":"failed"}]}\n' > "$B/missions/demo.dag.json"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
}
LAB="$WORK/lab"; mklab "$LAB"
node "$AUX/mk-agents.mjs" "$HOME" "$LAB" aaaa1111-2222-3333-4444-555555555555
SCRIPTS_HOTE="$WORK/scripts-hote"; ln -s "$SCRIPTS" "$SCRIPTS_HOTE"
O="$LAB/.vibeflow/cockpit"; rm -f "$O/.cache/server.json"
mkdir -p "$WORK/fauxbin"; cp "$SCRIPTS/tests/temoins/fauxbin-claude/claude" "$WORK/fauxbin/claude"; chmod +x "$WORK/fauxbin/claude" # le moteur n'envoie aucune question sans « claude » sur le PATH du serveur (askState.engine) : la CI n'en a pas, le faux claude partagé des suites de lancement le remplace
( cd "$LAB" && PATH="$WORK/fauxbin:$PATH" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS_HOTE" exec node "$O/serve.mjs" --no-open --port "$(libre)" > "$WORK/serve.out" 2>&1 ) </dev/null >/dev/null 2>&1 &
SRV_PID=$!; PIDS+=($SRV_PID)
for _ in $(seq 1 300); do grep -q '"port"' "$O/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
PORT="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$O/.cache/server.json','utf8')).port)" 2>/dev/null || echo 0)"
assert_eq "K0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"
R="$(REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-moteur-carte.mjs" "$CHROME" "http://127.0.0.1:$PORT" mgr1 2>"$WORK/mesure.err")"
[ -n "${KEEP:-}" ] && printf '%s\n' "$R" > "$WORK/mesure.json"
E() { printf '%s' "$R" | node "$AUX/ev.mjs" "$1"; }

echo "=== K1 — fenêtre « Exporter une copie » ==="
assert_eq "K1.1 — à l'ouverture, le focus est dans la fenêtre" "$(E 'j.modale.dedans')" "true"
assert_eq "K1.2 — Échap ferme la fenêtre" "$(E 'j.modale.echap')" "true"
assert_eq "K1.3 — à la fermeture, le focus revient au bouton d'origine" "$(E 'j.modale.rendu')" "btn-export"
assert_eq "K1.4 — l'Échap de la fenêtre ne fait pas aussi remonter la carte d'un niveau" "$(E 'j.modale.pageIntacte')" "true"
assert_eq "K1.5 — un clic sur le fond ferme la fenêtre" "$(E 'j.modale.fond')" "true"
echo "=== K2 — noms accessibles ==="
assert_eq "K2.1 — la flèche d'envoi de la question s'appelle « Ask »" "$(E 'j.noms.envoi')" "Ask"
assert_eq "K2.2 — la copie du chemin s'appelle « Copy path »" "$(E 'j.noms.chemin')" "Copy path"
echo "=== K3 — « détail technique » : mêmes statistiques et mêmes libellés ==="
assert_eq "K3.1 — contrôle positif : la fiche porte « used by » non nul et un lien « Uses »" "$(E "j.stats.simple.stats.some((x) => /^[1-9][0-9]* used by$/.test(x)) && j.stats.simple.liens.includes('Uses')")" "true"
assert_eq "K3.2 — mêmes statistiques dans les deux modes (« used by » ne devient pas « 0 exports »)" "$(E 'j.stats.identique')" "true"
assert_eq "K3.3 — mêmes libellés de lien dans les deux modes (« Uses » ne devient pas « Imports »)" "$(E "JSON.stringify(j.stats.simple.liens) === JSON.stringify(j.stats.tech.liens) && j.stats.tech.liens.includes('Uses')")" "true"
echo "=== K4 — fiche d'un document ==="
assert_eq "K4.1 — la fiche d'un document dit « Mentions »" "$(E "j.document.titres.includes('Mentions')")" "true"
assert_eq "K4.2 — elle ne dit plus « Depends on »" "$(E "j.document.titres.includes('Depends on')")" "false"
assert_eq "K4.3 — une phrase explique la liste" "$(E 'j.document.note.length > 20')" "true"
assert_eq "K4.4 — aucune ligne ne parle d'appels" "$(E "j.document.liens.includes('Mention') && !j.document.liens.some((x) => /call/i.test(x))")" "true"
assert_eq "K4.5 — un script, lui, garde « Depends on » (le document est seul concerné)" "$(E "j.script.titres.includes('Depends on')")" "true"
echo "=== K5 — encart des noms générés ==="
assert_eq "K5.1 — l'encart nomme la commande réelle" "$(E "j.encart.texte.includes('/vf-cockpit build')")" "true"
assert_eq "K5.2 — l'encart porte un bouton « copier la commande »" "$(E 'j.encart.bouton')" "true"
assert_eq "K5.3 — le bouton copie la commande" "$(E 'j.encart.copie')" "/vf-cockpit build"
echo "=== K6, K7 — clavier ==="
assert_eq "K6.1 — chaque ligne du panneau est atteignable au Tab" "$(E 'j.rangees.total > 0 && j.rangees.total === j.rangees.auClavier')" "true"
assert_eq "K7.1 — contrôle positif : le focus était bien dans le panneau" "$(E 'j.echap.surLigne')" "true"
assert_eq "K7.2 — Échap avec le focus dans le panneau ne remonte pas d'un niveau" "$(E 'j.echap.apresLigne === j.echap.avant')" "true"
assert_eq "K7.3 — contrôle positif : Échap depuis le canevas remonte d'un niveau" "$(E 'j.echap.apresCanevas !== j.echap.avant')" "true"
echo "=== K8, K9 — anneau de focus et repérage ==="
assert_eq "K8.1 — la règle de l'anneau de l'en-tête existe hors de tout @media" "$(E 'j.bague')" "true"
assert_eq "K9.1 — le repérage n'a plus d'ombre diffuse" "$(E 'j.halo.ombre')" "false"
assert_eq "K9.2 — le repérage dure 700 ms au plus" "$(E 'j.halo.duree > 0 && j.halo.duree <= 700')" "true"
echo "=== K10, K11 — bulle de réponse ==="
assert_eq "K10.1 — la bulle fait 35 % de la fenêtre au plus (1 280 x 720)" "$(E 'j.feuille.part > 0 && j.feuille.part <= 35')" "true"
assert_eq "K10.2 — la bulle se referme quand on change de vue" "$(E 'j.jalon.bulleRefermee')" "true"
assert_eq "K11.1 — « Back to map » revient à la carte d'où partait la question" "$(E 'j.retour.arrivee === j.retour.depart && j.retour.depart !== "root"')" "true"
assert_eq "K11.2 — la réponse reste lisible après le retour" "$(E 'j.retour.bulleGardee')" "true"
echo "=== K12 — état réel d'un nœud de mission ==="
assert_eq "K12.1 — chaque ligne de la mission porte une pastille d'état" "$(E 'j.pastille.pastilles > 0 && j.pastille.pastilles === j.pastille.lignes.length')" "true"
assert_eq "K12.2 — plus aucun « 0 » à droite des éléments" "$(E "j.pastille.lignes.length > 0 && !j.pastille.lignes.some((x) => x === '0' || /lines/i.test(x))")" "true"
assert_eq "K12.3 — l'infobulle d'une carte dit l'état, plus « 0 lines »" "$(E "j.info.pastille && !/lines/i.test(j.info.texte)")" "true"
assert_eq "K12.4 — PU-G-036 : l'infobulle d'une carte dit « Clic droit : plus d'actions », avec son deux-points" "$(E "/clic droit\\s*:\\s*plus d'actions/.test(j.infoFr.texte.replace(/\\u00a0/g, ' '))")" "true"
echo "=== K18 — l'infobulle ne revient pas après une navigation par la recherche (PU-G-035, recette du 2026-11-08) ==="
for CAS in code1440 code768 projet1440; do
  assert_eq "K18.0 ($CAS) — témoin : l'infobulle était affichée avant la recherche et la recherche a changé de vue" "$(E "!j.infoRecherche.$CAS.erreur && j.infoRecherche.$CAS.avant.visible && j.infoRecherche.$CAS.arrivee !== j.infoRecherche.$CAS.depart")" "true"
  assert_eq "K18.1 ($CAS) — après Entrée dans la recherche, l'infobulle de l'ancienne carte n'est pas restée ni revenue (fermée, ou celle de la carte sous le pointeur)" "$(E "j.infoRecherche.$CAS.coherente")" "true"
done
assert_eq "K12.5 — PU-G-100 : le panneau de la phase 2 dit « Dépend de » (la phase 1), pas « Utilisé par »" "$(E "j.sens.p2.titres.join('|') + ' : ' + j.sens.p2.lignes.join('|')")" "Dépend de : Phase 1 · Socle"
assert_eq "K12.6 — PU-G-100 : le panneau de la phase 1 dit « Utilisé par » (la phase 2), pas « Dépend de »" "$(E "j.sens.p1.titres.join('|') + ' : ' + j.sens.p1.lignes.join('|')")" "Utilisé par : Phase 2 · Suite"
assert_eq "K12.7 — PU-G-100 : l'ordre des cartes de phase est celui d'avant (la phase 1 avant la phase 2, lien non inversé)" "$(E "j.sens.ordre.join('>')")" "n:ph-1>n:ph-2"
echo "=== K13 — onglet Équipe à 390 px ==="
assert_eq "K13.1 — contrôle positif : la session porte une grille d'au moins 3 cartes" "$(E 'j.equipe.cartes >= 3')" "true"
assert_eq "K13.2 — une seule colonne de cartes" "$(E 'j.equipe.colonnes')" "1"
assert_eq "K13.3 — aucune carte ne déborde de l'écran" "$(E 'j.equipe.debordent')" "0"
echo "=== K14 — panneau de détail par défaut ==="
assert_eq "K14.1 — à 768 px le panneau de détail est fermé par défaut" "$(E 'j.panneau.a768')" "false"
assert_eq "K14.2 — contrôle positif : à 1 024 px il est ouvert par défaut" "$(E 'j.panneau.a1024')" "true"
echo "=== K15 — colonnes de la vue d'une partie (DG-12, PU-G-040) ==="
assert_eq "K15.1 — contrôle positif : la vue a une colonne « Used by » et la carte sans lien" "$(E 'j.colonnes.appelants > 0 && j.colonnes.seul')" "true"
assert_eq "K15.2 — la carte sans lien est rangée dans la colonne du milieu, à droite de « Used by »" "$(E 'j.colonnes.apres')" "true"
assert_eq "K15.3 — aucune carte n'en recouvre une autre" "$(E 'j.colonnes.chevauche')" "false"
assert_eq "K15.4 — à l'ouverture, les titres de colonnes font 14 px à l'écran au moins" "$(E 'j.titres.ouverture.length > 0 && Math.min(...j.titres.ouverture) >= 14')" "true"
assert_eq "K15.5 — la carte éloignée (contrôle positif : zoom sous 0,7), ils gardent 14 px au moins" "$(E 'j.titres.k1 < 0.7 && Math.min(...j.titres.eloigne) >= 14')" "true"
echo "=== K16 — vue de réponse remise à zéro (DG-04, PU-G-059, PU-G-143, PU-G-144) ==="
assert_eq "K16.1 — contrôle positif : sur le tableau, le panneau montre bien son titre" "$(E 'j.retour059.surTableau')" "Titre du tableau"
assert_eq "K16.2 — Échap vers la vue d'ensemble : le panneau redevient celui de la vue d'ensemble" "$(E 'j.retour059.viaEchap.vue + "|" + j.retour059.viaEchap.titre + "|" + j.retour059.viaEchap.selection')" "$(E 'j.retour059.viaEchap.vue + "|" + j.retour059.racine + "|null"')"
assert_eq "K16.3 — le fil d'Ariane « Overview » : de même" "$(E 'j.retour059.viaFil.vue + "|" + j.retour059.viaFil.titre + "|" + j.retour059.viaFil.selection')" "$(E 'j.retour059.viaFil.vue + "|" + j.retour059.racine + "|null"')"
assert_eq "K16.4 — contrôle positif : une réponse avec cartes montre bien son tableau et son bouton se pose au retour" "$(E 'j.reponse.premier.vue + "|" + j.reponse.premier.titre')" "q:answer|Premier tableau"
assert_eq "K16.5 — une réponse sans carte, après un tableau : plus de bouton « Show answer board »" "$(E 'j.reponse.suivant.bouton')" "false"
assert_eq "K16.6 — … et le tableau de la question d'avant n'est plus affiché" "$(E 'j.reponse.suivant.titre !== "Premier tableau"')" "true"
assert_eq "K16.7 — une première réponse sans carte : pas de bouton « Show answer board »" "$(E 'j.reponse.frais.bouton')" "false"
assert_eq "K16.8 — … et ouvrir la vue de réponse sans réponse ne lève aucune erreur et ne change pas de vue" "$(E 'j.reponse.frais.apresAller.vue + "|" + j.reponse.frais.apresAller.erreurs.length')" "root|0"
echo "=== K17 — compteurs et homonymes du travail récent (DG-03, PU-G-054, PU-G-049) ==="
assert_eq "K17.1 — le titre du tableau dit le nombre du badge" "$(E 'j.recent.titre')" "Recent work · $(E 'j.recent.badge') cards"
assert_eq "K17.2 — contrôle positif : le lab a plus de 24 fichiers à mettre sur un tableau" "$(E 'j.recent.coupe.fichiers > 24')" "true"
assert_eq "K17.3 — un tableau coupé à 24 cartes dit l'écart dans son titre" "$(E 'j.recent.coupe.titre')" "Recent work · 24 of $(E 'j.recent.coupe.fichiers') cards"
assert_eq "K17.4 — contrôle positif : le panneau d'une partie liste deux modifications dedans" "$(E 'j.dedoublon.section && j.dedoublon.noms.length')" "2"
assert_eq "K17.5 — les deux README s'y distinguent par leur dossier parent" "$(E "j.dedoublon.noms.every((x) => /^Readme · \\S+/.test(x)) && new Set(j.dedoublon.noms).size === 2")" "true"

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
