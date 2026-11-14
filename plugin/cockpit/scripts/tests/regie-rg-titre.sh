# regie-rg-titre.sh — fragment du plan 73-06, SOURCÉ par test-cockpit-regie.sh (ne définit que des fonctions) : le titre « (N) vous attendent », la pastille de favicon et l'état « lu ».
#   RG0_ordre_titre (ordre de chargement, sortie assemblée) · RG11_lu (état « lu » : survol, clic, purge, stockage refusé, « Tout marquer comme relu »)
#   RG12_titre (compositeur : structure du dépôt, puis navigateur ; trois mutants, un par garde : compositeur abonné au `who`, écouteur vf:onglet, nettoyage par onglet, repli qui n'écrase pas le compositeur).
# Sections navigateur (CDP, chrome-regie-titre.mjs) : sans Chrome hors CI elles disent « NON VÉRIFIÉ » et ne comptent aucun PASS.
# Fixtures : noms et identifiants inventés ; lab jetable ; les « who » viennent de l'EventSource enveloppé, aucun processus.

[ -n "${RG_PAGE_COMMUN:-}" ] || { . "$TESTS_DIR/regie-page-commun.sh"; RG_PAGE_COMMUN=1; }

# ti_g <sortie> <expression sur j> : la valeur, ou « ERR:… » quand le harnais n'a rien pu jouer
ti_g() { local r; r="$(G "$1" 'j.erreur ? "ERR:" + j.erreur : (function(){ try { return ('"$2"'); } catch (e) { return "ERR:" + e.message; } })()' 2>/dev/null)"; printf '%s' "${r:-ERR:sortie vide}"; }
ti_ok() { assert_eq "$1" "$(ti_g "$2" "$3")" "$4"; }
# ti_page <scénario> <fichier> : serveur frais du lab jetable (celui du module COCKPIT_MODULE s'il est posé : mutant), harnais, arrêt ; la sortie JSON va dans <fichier>
ti_page() {
  local L="$WORK/lab-titre" out
  [ -d "$L" ] || rg_lab "$L"
  if [ -n "${COCKPIT_MODULE:-}" ]; then rg_init; COCKPIT_SORTIE="$L/.vibeflow/cockpit" cockpit_lancer "$L"; RG_PORT="${VF_PORT:-0}"; RG_PID="${VF_PID:-}"
  else rg_serveur "$L"; fi
  out="$(REAL_HOME="${REAL_HOME:-$HOME}" node "$TESTS_DIR/chrome-regie-titre.mjs" "$CHROME" "http://127.0.0.1:$RG_PORT/" "$1" 2>&1)"
  rg_arreter
  printf '%s\n' "$out" > "$2"
}

rg_RG0_ordre_titre() {
  cat > "$AUX/ordre-titre.mjs" <<'JS'
// ordre-titre.mjs <html> : « ok » si le repère du compositeur existe une fois, est le DERNIER repère `/* ui/… */`, vient après ceux de 76-vf-git-entete.js et de 80-vf-fr.js,
// et si aucun fichier ui/ qui vient après lui n'écrit document.title (hors commentaires) ; « faux:… » sinon
import fs from 'node:fs';
let t; try { t = fs.readFileSync(process.argv[2], 'utf8'); } catch { console.log('illisible'); process.exit(0); }
const re = /\/\* ui\/([^ ]+) \*\//g, ms = [...t.matchAll(re)].map((m) => ({ nom: m[1], at: m.index })), n = ms.filter((m) => m.nom === '90-vf-titre.js'), pb = [];
if (n.length !== 1) pb.push(`90-vf-titre.js ×${n.length}`);
else {
  if (ms[ms.length - 1].nom !== '90-vf-titre.js') pb.push('pas le dernier');
  for (const x of ['76-vf-git-entete.js', '80-vf-fr.js']) { const p = ms.find((m) => m.nom === x); if (!p || p.at > n[0].at) pb.push('pas après ' + x); }
  for (let i = ms.indexOf(n[0]) + 1; i < ms.length; i++) {
    const corps = t.slice(ms[i].at, i + 1 < ms.length ? ms[i + 1].at : undefined).replace(/\/\*[\s\S]*?\*\//g, '').replace(/(^|[^:"'`])\/\/.*$/gm, '$1');
    if (/document\.title\s*=[^=]/.test(corps)) pb.push('écrit le titre après lui : ' + ms[i].nom);
  }
}
console.log(pb.length ? 'faux:' + pb.join(',') : 'ok');
JS
  local L="$WORK/ordt-lab" r="" f; mkdir -p "$L/src" "$L/.planning"; printf 'x\n' > "$L/src/u.js"; printf '## Phases\n\n- [ ] **Phase 1: Socle** - jet\n' > "$L/.planning/ROADMAP.md"
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/ordt-build.out" 2>&1
  for f in index.html project.html; do r="$r$f=$(node "$AUX/ordre-titre.mjs" "$L/.vibeflow/cockpit/$f" 2>&1) "; done
  assert_eq "RG0.13 — le compositeur du titre existe une fois, dernier repère de la page, après 76-vf-git-entete.js et 80-vf-fr.js, sans écrivain du titre derrière lui" "$r" "index.html=ok project.html=ok "
}

rg_RG12_titre() {
  # ---------- structure (sans navigateur) : qui écrit document.title, et le compositeur sans observateur ni marqueur persistant ----------
  cat > "$AUX/titre-structure.mjs" <<'JS'
// titre-structure.mjs <dossier ui> <mode> : mode « ecrivains » = fichiers ui/*.js qui affectent document.title (hors commentaires) hors 90-vf-titre.js, 80-vf-fr.js et 00-vf-onglets.js (repli sans compositeur, RG12.9 prouve qu'avec lui il n'écrit pas) ;
// mode « compositeur » = « ok » si 90-vf-titre.js existe, sans `new MutationObserver` ni `.observe(` (hors commentaires) ni marqueur persistant dans ses huit premières lignes
import fs from 'node:fs'; import path from 'node:path';
const [, , dir, mode] = process.argv;
const nu = (t) => t.replace(/\/\*[\s\S]*?\*\//g, '').replace(/(^|[^:"'`])\/\/.*$/gm, '$1');
if (mode === 'ecrivains') {
  const r = fs.readdirSync(dir).filter((n) => n.endsWith('.js') && !['90-vf-titre.js', '80-vf-fr.js', '00-vf-onglets.js'].includes(n) && /document\.title\s*=[^=]/.test(nu(fs.readFileSync(path.join(dir, n), 'utf8'))));
  console.log(r.join(',') || 'aucun');
} else {
  let t; try { t = fs.readFileSync(path.join(dir, '90-vf-titre.js'), 'utf8'); } catch { console.log('fichier absent'); process.exit(0); }
  const pb = []; if (/new\s+MutationObserver|\.observe\s*\(/.test(nu(t))) pb.push('observateur');
  if (t.split('\n').slice(0, 8).some((l) => l.includes('vf-coquille: persistant'))) pb.push('marqueur persistant');
  console.log(pb.length ? 'faux:' + pb.join(',') : 'ok');
}
JS
  assert_eq "RG12.6 — dans ui/*.js, hors commentaires, document.title n'est affecté que par 90-vf-titre.js (et 80-vf-fr.js, 00-vf-onglets.js en repli)" "$(node "$AUX/titre-structure.mjs" "$UI" ecrivains)" "aucun"
  assert_eq "RG12.7 — 90-vf-titre.js : ni observateur du <title> ni marqueur « persistant » (P73-D-38, A53)" "$(node "$AUX/titre-structure.mjs" "$UI" compositeur)" "ok"

  # ---------- navigateur ----------
  rg_chrome || return 0
  ti_page titre "$WORK/ti-titre.json"
  local T="$WORK/ti-titre.json" P='"(2) vous attendent · "'
  ti_ok "RG12.1 — deux sessions « vous attend » : le titre dit « (2) vous attendent · <Onglet> · <nom> » sur Équipe, Projet et Code" "$T" \
    'j.deux.equipe.startsWith('"$P"' + "Équipe · ") + "|" + j.deux.projet.startsWith('"$P"' + "Projet · ") + "|" + j.deux.code.startsWith('"$P"' + "Code · ")' "true|true|true"
  ti_ok "RG12.2 — le préfixe survit à vf-git:signal et à une écriture du moteur (« x map »), une seule fois" "$T" \
    'j.signal + "|" + j.moteur.startsWith("(2) vous attendent · Projet · ")' "1|true"
  ti_ok "RG12.2 — trois changements d'onglet sans rechargement : préfixe présent, même nombre d'abonnés au who à chaque retour (un seul compositeur actif)" "$T" \
    'j.sansRecharge + "|" + j.deux.projet.startsWith("(2)") + "|" + (j.abonnes[0] === j.abonnes[3]) + "|" + (j.abonnes[1] === j.abonnes[4])' "true|true|true|true"
  ti_ok "RG12.8 — la Phase 80 écrit le titre brut puis émet vf:onglet : le compositeur recompose « (2) vous attendent · Projet · … » (jamais le titre brut)" "$T" \
    'j.aller.startsWith("(2) vous attendent · Projet · ") + "|" + !j.aller.includes("brut")' "true|true"
  ti_ok "RG12.9 — un aller d'onglet réel (VF_ONGLETS) avec 2 sessions en attente : le préfixe reste, l'onglet d'arrivée est nommé, aucune écriture du titre nu « Onglet · nom » (un seul auteur du titre, 80-10)" "$T" \
    'j.allerOnglet.startsWith("(2) vous attendent · Code · ") + "|" + j.intermediaires.length' "true|0"
  ti_ok "RG12.9 — après TOUT vf:onglet (Code, Équipe, Projet) le titre servi est exactement celui que recompose 90-vf-titre.js : avec préfixe actif (n = 2) et sans préfixe (n = 0)" "$T" \
    'j.fidelesN.join() + "|" + j.fideles0.join()' "true,true,true|true,true,true"
  ti_ok "RG12.3 — une session : « (1) vous attend · … » au singulier ; aucune : « Projet · <nom> » et l'icône d'origine rendue" "$T" \
    'j.un.startsWith("(1) vous attend · Projet · ") + "|" + !j.un.includes("attendent") + "|" + j.zero.titre.startsWith("Équipe · ") + "|" + /^Projet · /.test(j.retour) + "|" + (j.hrefRetour === j.zero.href)' "true|true|true|true|true"
  ti_ok "RG12.4 — N > 0 : une icône data:image/svg+xml qui change l'icône d'origine, sans chiffre, aucune requête réseau d'icône, aucun message de la CSP" "$T" \
    'j.change + "|" + j.pastille.startsWith("data:image/svg+xml") + "|" + j.sansChiffre + "|" + j.reseau.length + "|" + j.csp.length' "true|true|true|0|0"
  ti_ok "RG12.5 — le focus reste où il était quand une poussée fait passer N de 0 à 2" "$T" 'j.focus' "vf-t-focus"

  # ---------- mutants (un par garde, copie du module jamais le dépôt) ----------
  rg_init
  local sain got f nom lib se ex
  tm() { # <nom> <libellé> <expression sed> <sonde JS> : la sonde rejouée sur la copie mutée doit différer de la valeur saine
    nom="$1"; lib="$2"; se="$3"; ex="$4"; f="$WORK/ti-mut-$nom.json"; sain="$(ti_g "$T" "$ex")"
    if ! cockpit_module_muter_page "ti-$nom" "$se" > /dev/null 2>&1; then assert_eq "M-$nom — $lib (ancre)" "ancre absente" "muté"; return 0; fi
    ti_page titre "$f"; unset COCKPIT_MODULE; got="$(ti_g "$f" "$ex")"
    if [ "$got" != "$sain" ]; then echo "  ✅ PASS — M-$nom — $lib (mutant tué : sonde $got, saine $sain)"; PASS=$((PASS+1))
    else echo "  ❌ FAIL — M-$nom — $lib (mutant survivant)"; echo "     attendu: [différent de $sain]"; echo "     obtenu:  [$got]"; FAIL=$((FAIL+1)); fi
  }
  tm TITRE-SANS-WHO "compositeur non abonné au who : le titre ne suit plus une poussée (RG12.1)" "s/E\.abonner('who', composer)/(() => () => {})()/" 'j.deux.equipe.startsWith("(2) vous attendent")'
  tm TITRE-SANS-ONGLET "compositeur sans écouteur de vf:onglet : l'aller d'onglet de la Phase 80 écrase le titre composé (RG12.8)" "s/ecouter(D, 'vf:onglet', composer);/void 0;/" 'j.aller.startsWith("(2) vous attendent")'
  tm TITRE-NETTOIE "nettoyage par onglet sans désabonnement : les abonnés au who s'accumulent (RG12.2)" "s/for (const f of defaire\.splice(0)) f();/for (const f of defaire.splice(0)) void f;/" '(j.abonnes[0] === j.abonnes[3]) + "|" + (j.abonnes[1] === j.abonnes[4])'
  tm TITRE-REPLI-ECRASE "00-vf-onglets.js sans le return de la branche compositeur : le repli écrit le titre nu avant que vf:onglet ne le recompose (RG12.9)" "s/T\.composer(); return; }/T.composer(); }/" 'j.fidelesN.join() + "|" + j.fideles0.join() + "|" + j.intermediaires.length'
}

rg_RG11_lu() {
  rg_chrome || return 0
  local L="$WORK/lab-titre" avant apres
  [ -d "$L" ] || rg_lab "$L"
  avant="$(git -C "$L" status --porcelain --untracked-files=all 2> /dev/null)"
  ti_page lu "$WORK/ti-lu.json"; ti_page tout-lu "$WORK/ti-tout.json"; ti_page lu-purge "$WORK/ti-purge.json"; ti_page lu-refuse "$WORK/ti-refuse.json"
  apres="$(git -C "$L" status --porcelain --untracked-files=all 2> /dev/null)"
  ti_ok "RG11.11 — survol de « Lire le rapport » : rien d'écrit ; clic : la clé vf-regie-lus:<lab> porte l'identifiant et une heure, la ligne passe aux « Relus ou sans rapport »" "$WORK/ti-lu.json" \
    'j.survol.length + "|" + j.cle.startsWith("vf-regie-lus:") + "|" + j.ids.join() + "|" + j.heureOk + "|" + j.avant + "|" + j.apres + "|" + /^Relus ou sans rapport/.test(j.relus)' "0|true|f0f0f0f0f0f0|true|1|0|true"
  ti_ok "RG11.12 — stockage préparé (24 h, valeur non numérique, identifiant hors forme, 250 valides) : au chargement les trois premières sont jetées, 200 au plus restent" "$WORK/ti-purge.json" \
    '(j.apres > 0 && j.apres <= 200) + "|" + j.vieux + "|" + j.nn + "|" + j.mauvais + "|" + j.recent' "true|false|false|false|true"
  ti_ok "RG11.13 — stockage refusé : toutes les lignes sont à relire, aucune exception, pas de « Tout marquer comme relu »" "$WORK/ti-refuse.json" \
    'j.lignes + "|" + j.bouton + "|" + j.exceptions' "3|false|0"
  ti_ok "RG11.14 — aucune requête autre que GET sur le scénario lu (survol, clic)" "$WORK/ti-lu.json" \
    'j.nonGet.length + "|" + j.nonGet.join()' "0|"
  ti_ok "RG11.14 — idem sur « Tout marquer comme relu »" "$WORK/ti-tout.json" 'j.nonGet.length' "0"
  assert_eq "RG11.14 — aucun fichier du lab modifié (git status avant et après)" "$apres" "$avant"
  ti_ok "RG11.15 — trois lignes à relire : un .btn « Tout marquer comme relu » qui vide la section (« Aucun rapport à relire. ») ; deux lignes : pas de bouton" "$WORK/ti-tout.json" \
    '(j.trois ? j.trois.texte : "-") + "|" + (j.trois && /(^| )btn( |$)/.test(j.trois.classe)) + "|" + j.vide + "|" + (j.deux === null)' "Tout marquer comme relu|true|Aucun rapport à relire.|true"
}
