#!/usr/bin/env bash
# test-cockpit-surcouches.sh — pile unique de surcouches (80-02 : FORM-02, AUDC-M6, P80-D-11, D-34, D-59 a), sans réseau.
#   SU1 palette : Tab hors du champ puis Échap la ferme et rend le focus ; un seul Échap dans le champ ; garde d'unicité (réévaluation du module)
#   SU2 export : 15 Tab restent dans la boîte, Maj+Tab boucle, inert posé puis levé (jamais celui d'un témoin), focus rendu ; palette : 30 Tab
#   SU3 panneau fermé : aucun focalisable (1440 px), focus rendu au bouton, mouvement réduit
#   SU4 tiroirs et Échap : dessus de pile, palette sur tiroir, contrat Échap consommé (Code, Équipe, Terminal), ordre des écouteurs, cas interdit
#   SU5 les trois listes recopiées ont disparu · SU6 coquille de la 79 : la pile est un persistant (deux allers-retours Code / Projet : même objet, un seul écouteur)
#   Mutants (copie COMPLÈTE du module par cockpit_module_copie, page rebâtie depuis la copie, serveur lancé par socle-serveur.sh sur COCKPIT_MODULE ;
#   jamais le module du dépôt, jamais un lien) : M-INERT-TOUT, M-PIEGE, M-PALETTE, M-ECHAP-VIDE, M-SANS-PREVENT, M-UNICITE, M-LEVEE, M-PROPRIO,
#   M-TIROIR-COUVERT, M-FLUX, M-BULLE, M-RIEN, M-IDPANEL, M-RENDRE, M-TOUR, M-PERSISTANT (marqueur retiré)
# Sans navigateur : la suite se déclare SAUTÉE (exit 0, message explicite) — jamais un vert à vide. Exit 0 si tout passe.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$SCRIPTS/../skills/cockpit-moteur"; UI="$ENG/assets/ui"; PILE="$UI/00-vf-surcouches.js"
CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then
  . "$HERE_T/chrome-saut.sh"
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur — la pile de surcouches NON vérifiée, non comptée comme réussie"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
. "$HERE_T/socle-serveur.sh"
PASS=0; FAIL=0; MUTANTS=0
assert_eq() {
  if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1))
  else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:600}]"; FAIL=$((FAIL+1)); fi
}
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('sortie illisible'); process.exit(0); }
if (j.erreur) { console.log('mesure indisponible : ' + j.erreur); process.exit(0); }
const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/chg.mjs" <<'JS'
import fs from 'node:fs'; const [, , a, b] = process.argv; const x = fs.readFileSync(a, 'utf8').split('\n'), y = fs.readFileSync(b, 'utf8').split('\n');
// la ligne des données (« window.VF_COCKPIT = … », avec generatedAt) change à chaque assemblage : ce n'est pas la mutation
const donnees = (l) => l.startsWith('<script>window.VF_COCKPIT = ');
console.log(x.length === y.length ? x.filter((l, i) => l !== y[i] && !(donnees(l) && donnees(y[i]))).length : -1);
JS
cat > "$AUX/mk-agents.mjs" <<'JS'
import fs from 'node:fs'; import path from 'node:path';
const [, , home, lab, sid] = process.argv; const now = Date.now(); const iso = (ms) => new Date(ms).toISOString();
const dir = path.join(home, '.claude', 'projects', '-lab'); const sub = path.join(dir, sid, 'subagents'); fs.mkdirSync(sub, { recursive: true });
const base = (o) => ({ cwd: lab, sessionId: sid, gitBranch: 'main', version: '2.1.317', ...o });
const put = (f, l) => fs.writeFileSync(f, l.map((x) => JSON.stringify(x)).join('\n') + '\n');
const outil = (name, input) => ({ content: [{ type: 'tool_use', name, input }] });
put(path.join(dir, sid + '.jsonl'), [base({ type: 'user', timestamp: iso(now - 600000), message: { content: 'salut' } }),
  base({ type: 'assistant', timestamp: iso(now - 5000), message: outil('Bash', { command: 'echo bonjour' }) })]);
const meta = { agentType: 'vf-coder', isBuiltIn: false, launchedWithDefaults: false, description: 'tâche synthétique', toolUseId: 'toolu_a1', spawnDepth: 1 };
fs.writeFileSync(path.join(sub, 'agent-a1.meta.json'), JSON.stringify(meta));
const ag = { isSidechain: true, agentId: 'a1' };
put(path.join(sub, 'agent-a1.jsonl'), [
  base({ type: 'user', ...ag, parentUuid: null, timestamp: iso(now - 300000), message: { role: 'user', content: 'mandat' } }),
  base({ type: 'assistant', ...ag, timestamp: iso(now - 4000), message: outil('Read', { file_path: '/x' }) })]);
JS
mklab() { # un module, une phase, un dépôt git (le tiroir Git et la touche g existent)
  local L="$1" B="$1/.planning" N; N="$WORK/build-$(basename "$1").out"
  mkdir -p "$L/src" "$L/plugin/mod/scripts" "$B/phases/01-socle"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"
  printf '{"name":"mod","type":"skill","description":"Un module de test."}\n' > "$L/plugin/mod/module.json"; echo 1.0.0 > "$L/plugin/mod/VERSION"
  printf '# Module\n\nLancer `run.sh`.\n' > "$L/plugin/mod/README.md"; printf '#!/usr/bin/env bash\necho run\n' > "$L/plugin/mod/scripts/run.sh"
  printf '# Titre du projet\n' > "$B/PROJECT.md"
  printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Depends on**: Nothing (first phase)\n' > "$B/ROADMAP.md"
  printf -- '---\nfiles_modified: [plugin/mod/README.md]\n---\n<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  git -C "$L" init -q -b main && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$N" 2>&1 || cat "$N"
}
mkdir -p "$WORK/fauxbin"; cp "$SCRIPTS/tests/temoins/fauxbin-claude/claude" "$WORK/fauxbin/claude"; chmod +x "$WORK/fauxbin/claude"
serve() { # serve <lab> [--terminal] : serveur en fond lancé par le socle (cockpit_lancer), port dans SERVED, code du lanceur dans SERVED_RC (COCKPIT_MODULE : le module servi)
  local lab="$1" o="$1/.vibeflow/cockpit" pret=port; shift
  local env=(PATH="$WORK/fauxbin:$PATH") opt=(); [ -z "${SANS_CLI:-}" ] || { mkdir -p "$WORK/vide"; env=(PATH="$WORK/vide:/usr/bin:/bin"); opt=(--claude "$WORK/absent"); } # SANS_CLI=1 : serveur sans CLI (barre de question absente), passage de la jointure J1
  if [ "${1:-}" = "--terminal" ]; then
    pret=terminal; mkdir -p "$o/.cache"; rm -f "$o/.cache/terminal-amorce"
    (umask 077; node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" | tr -d '\n' > "$o/.cache/terminal-amorce")
  fi
  COCKPIT_PRET="$pret" COCKPIT_LOG="$WORK/serve-$(basename "$lab").out" cockpit_lancer "$lab" "${env[@]}" SHELL=/bin/sh VF_COCKPIT_TERM_GRACE_MS=5000 "$@" ${opt[@]+"${opt[@]}"}
  SERVED_RC=$?; SERVED="$VF_PORT"
}
LAB="$WORK/lab"; mklab "$LAB"; node "$AUX/mk-agents.mjs" "$HOME" "$LAB" aaaa1111-2222-3333-4444-555555555555
O="$LAB/.vibeflow/cockpit"; serve "$LAB"; PORT="$SERVED"
assert_eq "A0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"
TL="$WORK/lab-term"; mklab "$TL"; serve "$TL" --terminal; PORT_T="$SERVED"
pilote() { # pilote <port> <module> <racine-terminal> <sections>
  REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-surcouches.mjs" "$CHROME" "http://127.0.0.1:$1" "$2" "${3:-}" "${4:-su1,su2,su3,su4,su6,su7}" 2>"$WORK/mesure.err"
}
# SU_SECTIONS : mise au point (sections jouées) ; SU_SANS_MUTANTS=1 saute les mutants
R="$(pilote "$PORT" "$PILE" "http://127.0.0.1:$PORT_T" "${SU_SECTIONS:-su1,su2,su3,su4,su6,su7}")"
[ -n "${KEEP:-}" ] && printf '%s\n' "$R" > "$WORK/mesure.json"
[ -n "${SONDE:-}" ] && { printf '%s\n' "$R"; cat "$WORK/mesure.err"; }
E() { printf '%s' "$R" | node "$AUX/ev.mjs" "$1"; }
ok() { assert_eq "$1" "$(E "$2")" "${3:-true}"; } # ok <libellé> <expression sur j> [attendu]

echo "=== SU1 — palette : Tab hors du champ, Échap (AUDC-M6) ==="
ok "SU1.1 — palette ouverte, Tab hors du champ, Échap : fermée, focus rendu à l'élément d'avant" \
  "j.su1.ferme && j.su1.retour === 'btn-export'"
ok "SU1.2 — Échap dans le champ de recherche ferme encore la palette en un appui" 'j.su1.champ'
ok "SU1.3 — le module réévalué ne change ni l'identité de VF_SURCOUCHES ni le nombre d'écouteurs ; SU1.1 reste vrai" \
  "j.su1.api === 'object' && j.su1.identite && j.su1.nouveaux === 0 && j.su1.rejoue"
echo "=== SU2 — modale : piège à Tab, inert suivi, retour à l'ouvreur ==="
ok "SU2.1 — export ouvert, 15 Tab : le focus reste dans la boîte ; Maj+Tab depuis le premier : le dernier" \
  'j.su2.arrets.length === 15 && j.su2.arrets.every(Boolean) && j.su2.maj'
ok "SU2.2 — modale : en-tête, scène et panneau inertes ; fermée par Échap : plus d'inert de la pile, focus sur #btn-export" \
  "j.su2.pendant === 'true,true,true' && j.su2.ferme && j.su2.focus === 'btn-export' \
    && j.su2.apres.split(',').filter((x) => x && x !== 'vf-temoin-inert').length === 0"
ok "SU2.3 — l'élément témoin déjà inert avant l'ouverture l'est encore après la fermeture" \
  "j.su2.avant === 'vf-temoin-inert' && j.su2.apres.split(',').includes('vf-temoin-inert')"
ok "SU2.4 — palette ouverte, 30 Tab : le focus reste dans la boîte" 'j.su2.pal.length === 30 && j.su2.pal.every(Boolean)'
echo "=== SU3 — panneau latéral fermé hors de la tabulation (AUDC-M6) ==="
ok "SU3.1 — 1440 px : panneau ouvert, des focalisables ; fermé (p) : aucun focalisable visible" \
  'j.su3.ouvert > 0 && j.su3.ferme && j.su3.focalisables === 0'
ok "SU3.2 — le focus était dans le panneau que p ferme : il va à #btn-panel" "j.su3.dansPanneau && j.su3.focus === 'btn-panel'"
ok "SU3.3 — mouvement réduit : panneau fermé, visibility: hidden posé sans attendre la transition" 'j.su3.reduit' hidden
echo "=== SU4 — tiroirs, ordre d'Échap et contrat consommé (Phases 73 et 74) ==="
ok "SU4.1 — tiroir Git ouvert, focus sur body : Échap le ferme, la sélection reste ; l'Échap suivant la lève" \
  'j.su4.tiroirFerme && j.su4.selGardee && j.su4.selLevee'
ok "SU4.2 — palette ouverte sur le tiroir Git : Échap ferme la palette, le tiroir reste" 'j.su4.palFerme && j.su4.tiroirResteOuvert'
ok "SU4.3 — dessus() : le tiroir Git seul, puis #palette quand elle est ouverte par-dessus" 'j.su4.dessusTiroir && j.su4.dessusPalette'
ok "SU4.4 — Échap consommé (Code, Équipe) : palette fermée, defaultPrevented vrai pour le témoin, vue non appelée" \
  "['consomme_index', 'consomme_equipe'].every((k) => j.su4[k].ferme && j.su4[k].temoin.length === 1 && j.su4[k].temoin[0] === true && j.su4[k].vue === 0)"
ok "SU4.5 — aucune surcouche : Échap arrive intact à la vue (defaultPrevented faux), Code et Équipe" \
  "['index', 'equipe'].every((k) => j.su4['ouverte_' + k] === false && j.su4['vide_' + k].temoin[0] === false && j.su4['vide_' + k].vue === 1)"
if [ "$(E 'j.su4.terminal && j.su4.terminal.sautee ? 1 : 0')" = "1" ]; then
  echo "  ⊘ SU4.5b SAUTÉ — Terminal non lancé : $(E 'j.su4.terminal.sautee') (non compté comme réussi)"
else
  ok "SU4.5b — focus dans la région du Terminal : la pile n'agit pas (defaultPrevented faux, vue appelée)" \
    'j.su4.terminal.temoin[0] === false && j.su4.terminal.vue === 1 && j.su4.terminal.ouverte === false'
fi
ok "SU4.6 — un seul écouteur Échap de la pile, posé avant tout écouteur d'extension ; palette fermée malgré le cas interdit" \
  'j.su4.ordre.pile === 1 && j.su4.ordre.avantTout && j.su4.ordre.dernier > 0 && j.su4.consomme_index.ferme'
echo "  ℹ cas interdit : constat documenté — un écouteur en capture sur window posé AVANT la pile reçoit l'appui" \
  "avec defaultPrevented = $(E 'j.su4.consomme_index.interdit.slice(-1).join()') (ni PASS ni FAIL de la pile)"
echo "=== SU7 — corrections de la revue : inert, tiroirs couverts, gardes d'Échap, visite modale ==="
ok "SU7.1 — palette : Entrée sur une recherche vide et clic dans #results hors d'une ligne la laissent ouverte ET inerte ; Échap lève tout" \
  "j.su7.entree.ouverte && j.su7.entree.inert.length > 0 && j.su7.clic.ouverte && j.su7.clic.inert.length > 0 && !j.su7.fin.ouverte && j.su7.fin.inert === ''"
ok "SU7.2 — palette fermée et modale ouverte dans le même tour : le fond reste inerte sous la modale, levé à sa fermeture" \
  "j.su7.deux.modale && j.su7.deux.inert.split(',').includes('stage') && !j.su7.deux.inert.split(',').includes('modal') && j.su7.deuxFin === ''"
ok "SU7.3 — « Au travail » puis Git ouverts, focus dans « Au travail » : Échap ferme « Au travail » (régression de la base), Git reste" \
  "j.su7.tiroirs === '{\"git\":true,\"whop\":false}'"
ok "SU7.4 — un parcours en cours : Échap ne ferme pas le tiroir Git (garde flux)" 'j.su7.flux'
ok "SU7.5 — une bulle d'aide visible : Échap ne ferme pas le tiroir Git (garde bulle)" 'j.su7.bulle'
ok "SU7.6 — focus sur un bouton hors du tiroir : Échap ne ferme pas le tiroir Git (garde rien)" 'j.su7.rien'
ok "SU7.7 — la feuille de détail (role=dialog visible, 600 px) n'est pas une surcouche : ouverte() faux" \
  "j.su7.feuille === '{\"role\":\"dialog:true\",\"ouverte\":false}'"
ok "SU7.8 — modale inscrite par l'API : fermer() rend le focus à son ouvreur" 'j.su7.rendre'
ok "SU7.9 — visite ouverte par son bouton : modale (25 Tab dans #tour, inert posé, levé à la fermeture)" \
  "j.su7.tour.actif && j.su7.tour.arrets.every(Boolean) && j.su7.tour.inert.length > 0 && !j.su7.tour.fin.actif && j.su7.tour.fin.inert === ''"
ok "SU7.10 — visite ouverte d'elle-même : non modale (aucun inert)" 'j.auto.actif && j.auto.inert === 0'
echo "=== SU5 — les listes recopiées ont disparu (retrait 4) ==="
assert_eq "SU5.1 — « #palette.open, #flowmenu.open » absent de 02, 73 et 77 (baseline : 1 dans chacun)" \
  "$(cd "$UI" && grep -lF '#palette.open, #flowmenu.open' 02-vf-telephone.js 73-vf-tiroir-travail.js 77-vf-git-tiroir.js | tr '\n' ',')" ""
echo "=== SU6 — coquille de la 79 ==="
ok "SU6.1 — deux allers-retours Code / Projet, tiroir Git ouvert avant le départ : VF_SURCOUCHES est le même objet, UN seul écouteur Échap en capture posé par la pile, le tiroir est retiré de la pile avec l'onglet" \
  "j.su6.avant && j.su6.identite && j.su6.pile === 1 && j.su6.onglet === 'code' && j.su6.retire"
if [ "$(E 'j.su6.terminal && j.su6.terminal.sautee ? 1 : 0')" = "1" ]; then
  echo "  ⊘ SU6.1b SAUTÉ — Terminal non lancé : $(E 'j.su6.terminal.sautee') (non compté comme réussi)"
else
  ok "SU6.1b — Terminal rouvert après les allers-retours, focus dans sa région : la pile n'agit pas (defaultPrevented faux, vue appelée)" \
    'j.su6.terminal && j.su6.terminal.temoin[0] === false && j.su6.terminal.vue === 1'
fi
echo "=== Mutants (copie du module, page rebâtie, serveur sur la copie) ==="
[ -z "${SU_SANS_MUTANTS:-}" ] || { echo "  ⊘ mutants sautés (SU_SANS_MUTANTS) : mise au point seulement"; vf_hyg_assert; exit 0; }
mutant() { # mutant <nom> <sections> <motif sed> <assertion> : copie du module, motif appliqué DANS LA COPIE, serveur sur la copie (empreinte publiée = celle de la copie), attend ROUGE
  local nom="$1" sec="$2" motif="$3" test="$4" ml="$WORK/lab-mut-$1" nj port RM M f
  rm -rf "$ml" "$WORK/mod-$nom"; cp -R "$LAB" "$ml" # un lab entier : le tiroir Git a besoin de son dépôt
  M="$(cockpit_module_copie "$WORK/mod-$nom")" || { echo "  ❌ FAIL — mutant $nom : copie du module impossible"; FAIL=$((FAIL+1)); return; }
  f="$M/skills/cockpit-moteur/assets/ui/00-vf-surcouches.js"
  sed -i.bak "$motif" "$f"; rm -f "$f.bak"
  node "$M/scripts/vf-cockpit-build.mjs" "$ml" --quiet > "$WORK/build-mut-$nom.out" 2>&1 || cat "$WORK/build-mut-$nom.out"
  nj="$(node "$AUX/chg.mjs" "$PILE" "$f")" # les scripts ui/ sont servis par la coquille (/_vf/), plus inlinés dans la page : la copie doit avoir changé, et c'est elle qui est chargée (code 5)
  [ "$nj" -ge 1 ] || { echo "  ❌ FAIL — mutant $nom : la copie du module n'a pas changé ($nj ligne)"; FAIL=$((FAIL+1)); return; }
  COCKPIT_MODULE="$M" serve "$ml"; port="$SERVED"
  [ "$SERVED_RC" = 0 ] || { echo "  ❌ FAIL — mutant $nom : serveur non lancé sur la copie (code $SERVED_RC ; 5 = la copie n'est pas celle qui est chargée)"; FAIL=$((FAIL+1)); return; }
  RM="$(pilote "$port" "$f" "" "$sec")"; cockpit_arreter
  if [ "$(printf '%s' "$RM" | node "$AUX/ev.mjs" "$test")" = "false" ]; then
    echo "  ✅ PASS — $nom : le mutant rougit (assertion « $test » = false ; copie chargée : empreinte publiée = celle de la copie ; $nj ligne(s) changée(s) dans le module servi)"; PASS=$((PASS+1)); MUTANTS=$((MUTANTS+1))
  else echo "  ❌ FAIL — $nom : le mutant ne rougit pas"; echo "     sortie: ${RM:0:400}"; FAIL=$((FAIL+1)); fi
}
mutant M-INERT-TOUT su2 's#for (const x of e.inertes)#for (const x of document.querySelectorAll("[inert]"))#' \
  "j.su2.apres.split(',').includes('vf-temoin-inert')"
mutant M-PIEGE su2 "s#if (ev.key === 'Tab' && modale)#if (false)#" 'j.su2.arrets.every(Boolean) && j.su2.maj'
mutant M-PALETTE su1 "s#par('pal-x').click()#void 0#" 'j.su1.ferme'
mutant M-ECHAP-VIDE su4i 's#{ // vf-echap$#{ ev.preventDefault(); ev.stopPropagation();#' \
  "j.su4.vide_index.temoin[0] === false && j.su4.vide_index.vue === 1"
mutant M-SANS-PREVENT su4i 's#const consomme = (ev) => { ev.preventDefault();#const consomme = (ev) => {#' \
  'j.su4.consomme_index.temoin[0] === true'
mutant M-UNICITE su1 's#if (window.VF_SURCOUCHES) return;##' 'j.su1.identite && j.su1.nouveaux === 0'
mutant M-LEVEE su7 's|if (pile.includes(h) \&\& h.modale \&\& !h.inertes.length) inerter(h);|void 0;|' \
  "j.su7.entree.inert.length > 0 && j.su7.clic.inert.length > 0"
mutant M-PROPRIO su7 's|if (n > 0) { prop.set(x, n); continue; }||' "j.su7.deux.inert.split(',').includes('stage')"
mutant M-TIROIR-COUVERT su7 's|if (d) { consomme(ev); d.fermer(); }||' "j.su7.tiroirs === '{\"git\":true,\"whop\":false}'"
mutant M-FLUX su7 's|if (rien(t) \&\& !flux|if (rien(t)|' 'j.su7.flux'
mutant M-BULLE su7 's#\.vf-git-bulle:not(\[hidden\]), \#sc-gloss\.on#.zz-vide#' 'j.su7.bulle'
mutant M-RIEN su7 's|if (rien(t) \&\& !flux|if (!flux|' 'j.su7.rien'
mutant M-IDPANEL su7 "s|d.id !== 'panel' \&\& ||" 'j.su7.feuille === '"'"'{"role":"dialog:true","ouverte":false}'"'"
mutant M-RENDRE su7 's|if (e.rendu) rendre(e);|void 0;|' 'j.su7.rendre'
mutant M-TOUR su7 's|if (tv \&\& !dT \&\& refs.tourBtn)|if (false)|' 'j.su7.tour.arrets.every(Boolean)'
mutant M-PERSISTANT su6 's#^// vf-coquille: persistant$#// vf-coquille : retiré#' 'j.su6.identite && j.su6.pile === 1'
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
