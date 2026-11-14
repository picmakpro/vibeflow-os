# regie-rg-pied.sh — fragment du plan 73-07, SOURCÉ par test-cockpit-regie.sh (ne définit que des fonctions) : le pied de la régie.
#   RG8_pied (arbres de travail : replié, lu à l'ouverture et sur l'événement git, « non vérifié », jointure par branche unique, noms en doublon, échec) ·
#   RG13_page (ligne « Ailleurs sur ce poste » et sa non-fuite de bout en bout, un mutant par support de fuite) · RG14_fr (données non traduites) · RG16_export (l'export n'emporte rien de la régie).
# Sections navigateur (CDP) : sans Chrome hors CI elles disent « NON VÉRIFIÉ » et ne comptent aucun PASS. Fixtures : noms et identifiants inventés, chemins construits à l'exécution sous $WORK ;
# faux `claude` dans $WORK/pi-bin (le serveur le trouve par son PATH). Un seul mutant par support de fuite (page, flux), joué sur une copie du module : jamais le dépôt.

[ -n "${RG_PAGE_COMMUN:-}" ] || { . "$TESTS_DIR/regie-page-commun.sh"; RG_PAGE_COMMUN=1; }

# pi_g <sortie> <expression sur j> : la valeur, ou « ERR:… » quand le harnais n'a rien pu jouer
pi_g() { local r; r="$(G "$1" 'j.erreur ? "ERR:" + j.erreur : (function(){ try { return ('"$2"'); } catch (e) { return "ERR:" + e.message; } })()' 2>/dev/null)"; printf '%s' "${r:-ERR:sortie vide}"; }
pi_ok() { assert_eq "$1" "$(pi_g "$2" "$3")" "$4"; }
pi_rep() { local d; d="$(cd "$1" && pwd -P)"; printf '%s' "$d"; }
# pi_serveur <lab> [NOM=valeur…] : serveur du lab (celui du module COCKPIT_MODULE s'il est posé : mutant) ; RG_PORT, RG_PID (shell courant)
pi_serveur() {
  local L="$1"; shift; rg_init
  if [ -n "${COCKPIT_MODULE:-}" ]; then COCKPIT_SORTIE="$L/.vibeflow/cockpit" cockpit_lancer "$L" "$@"
  else COCKPIT_SORTIE="$L/.vibeflow/cockpit" cockpit_lancer "$L" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" "$@"; fi
  RG_PORT="${VF_PORT:-0}"; RG_PID="${VF_PID:-}"
}
# pi_page <scénario> <lab> <fichier> [json] [NOM=valeur…] : serveur frais, harnais, arrêt ; la sortie JSON va dans <fichier>
pi_page() {
  local sc="$1" L="$2" f="$3" js="${4:-}" h=chrome-regie-pied.mjs out; shift 4 2> /dev/null || shift $#
  [ "$sc" != fuite ] || h=chrome-regie-fuite.mjs
  [ -d "$L" ] || rg_lab "$L"
  : > "$WORK/pi-marqueur"; sleep 0.2
  pi_serveur "$L" "$@"
  out="$(REAL_HOME="${REAL_HOME:-$HOME}" node "$TESTS_DIR/$h" "$CHROME" "http://127.0.0.1:$RG_PORT/equipe.html" "$sc" "$js" 2>&1)"
  rg_arreter
  printf '%s\n' "$out" > "$f"
}
pi_valider() { git -C "$1" -c user.email=t@t -c user.name=t commit -q -m "$2"; }
pi_lab_arbres() { # trois arbres : le principal, un worktree (3 modifiés, 2 non suivis), un worktree au lien retour forgé (« non vérifié »)
  local L="$WORK/lab-arb" w="$WORK/wt-a" f g
  [ -d "$L" ] && return 0
  rg_lab "$L"; L="$(pi_rep "$L")"; git -C "$L" worktree add -q -b wa "$w"; w="$(pi_rep "$w")"
  for f in src/util.js .planning/ROADMAP.md .planning/phases/01-socle/01-01-PLAN.md; do printf 'ligne ajoutée\n' >> "$w/$f"; done
  printf 'a\n' > "$w/neuf1.txt"; printf 'b\n' > "$w/neuf2.txt"
  mkdir -p "$WORK/wt-forge" "$L/.git/worktrees/forge1"; g="$L/.git/worktrees/forge1"
  printf '%s\n' "$(pi_rep "$WORK/wt-forge")/.git" > "$g/gitdir"; printf 'ref: refs/heads/main\n' > "$g/HEAD"; printf '../..\n' > "$g/commondir"
  PI_CHEMINS="[\"$L\",\"$w\",\"$(pi_rep "$WORK/wt-forge")\"]"
}
pi_lab_doublon() { # cinq arbres : deux de même nom « same », deux sur la même branche « dup » (git --force), un worktree d'une branche unique « b1 » à 1 modifié
  local L="$WORK/lab-dup"
  [ -d "$L" ] && return 0
  rg_lab "$L"; L="$(pi_rep "$L")"; mkdir -p "$WORK/x1" "$WORK/x2" "$WORK/x3" "$WORK/x4"
  git -C "$L" worktree add -q -b b1 "$WORK/x1/same"; git -C "$L" worktree add -q -b b2 "$WORK/x2/same"
  git -C "$L" worktree add -q -b dup "$WORK/x3/uno"; git -C "$L" worktree add -q -f "$WORK/x4/duo" dup
  printf 'ligne ajoutée\n' >> "$WORK/x1/same/src/util.js"; printf 'ligne ajoutée\n' >> "$WORK/x3/uno/src/util.js"
  PI_CHEMINS="[\"$L\",\"$(pi_rep "$WORK/x1/same")\",\"$(pi_rep "$WORK/x2/same")\",\"$(pi_rep "$WORK/x3/uno")\",\"$(pi_rep "$WORK/x4/duo")\"]"
}

rg_RG8_pied() {
  rg_chrome || return 0
  pi_lab_arbres; pi_page arbres "$WORK/lab-arb" "$WORK/pi-arbres.json" "{\"chemins\":$PI_CHEMINS}"
  pi_lab_doublon; pi_page doublon "$WORK/lab-dup" "$WORK/pi-doublon.json" "{\"chemins\":$PI_CHEMINS}"
  pi_page echec "$WORK/lab-page" "$WORK/pi-echec.json" ""
  local A="$WORK/pi-arbres.json" D="$WORK/pi-doublon.json"
  pi_ok "RG8.1 — trois arbres : « Arbres de travail » replié ; ouvert « (3) », « 3 modifiés » et « 2 non suivis » sur le worktree, « ici » sur un seul arbre, « non vérifié » SANS compte ni « propre » sur l'arbre au lien forgé" "$A" \
    '(function(){ const L = j.ouvert.lignes, w = L.find((l) => l.includes("wt-a")) || "", f = L.find((l) => l.includes("wt-forge")) || "-", p = L.find((l) => l.includes("lab-arb")) || "";
      return [j.avant.bloc.ouvert, /^Arbres de travail/.test(j.avant.bloc.titre), j.ouvert.ouvert, /Arbres de travail \(3\)/.test(j.ouvert.titre), L.length, /3 modifiés/.test(w), /2 non suivis/.test(w),
        /\bici\b/.test(p), L.filter((l) => /\bici\b/.test(l)).length, /non vérifié/.test(f), !/propre|modifi|non suivi/.test(f)].join("|"); })()' \
    "false|true|true|true|3|true|true|true|1|true|true"
  pi_ok "RG8.2 — aucune lecture Git avant l'ouverture ; ouverture : /api/vf/git et /api/vf/git/worktrees, une fois chacune ; l'événement git : une relecture (2 requêtes) ; 35 s sans événement : aucune requête ; rien d'autre qu'un GET" "$A" \
    'j.avant.lectures.length + "|" + j.apres.lectures.slice().sort().join(",") + "|" + j.signal + "|" + j.minuterie + "|" + j.nonGet.length' \
    "0|/api/vf/git,/api/vf/git/worktrees|2|0|0"
  pi_ok "RG8.3 — précondition (le bloc ouvert montre au moins un arbre) puis aucun chemin absolu d'arbre ni commande « cd » dans section#vf-equipe" "$A" \
    '(j.ouvert.lignes.length >= 1) + "|" + j.chemins.length + "|" + j.cd' "true|0|false"
  pi_ok "RG8.4 — un agent dont la branche désigne un seul arbre : « 3 modifiés » en ligne 2 après l'ouverture, rien avant ; deux arbres sur la même branche : rien (jamais deviné), la branche unique d'un autre arbre le dit" "$A" \
    '(j.avant.l2 !== null && !/modifi/.test(j.avant.l2)) + "|" + /3 modifiés/.test(j.apres.l2)' "true|true"
  pi_ok "RG8.4 — (doublon) deux arbres sur la branche « dup » : rien ; un seul arbre sur « b1 » : « 1 modifié »" "$D" \
    '(j.apres.l2 !== null && !/modifi/.test(j.apres.l2)) + "|" + /1 modifié/.test(j.apres.l2b)' "true|true"
  pi_ok "RG8.5 — routes Git en échec : « Git est indisponible » et un .btn « Réessayer » ; au rétablissement et au clic : « Un seul arbre de travail. »" "$WORK/pi-echec.json" \
    '/Git est indisponible/.test(j.ko.corps) + "|" + j.ko.btn.includes("Réessayer") + "|" + /Un seul arbre de travail\./.test(j.seul.corps)' "true|true|true"
  pi_ok "RG8.6 — A46 : deux arbres vérifiés de même nom : les DEUX lignes, chacune avec « nom partagé : aucune cible rattachable », aucun chemin ; les trois autres (noms uniques) sans la mention" "$D" \
    '(function(){ const L = j.ouvert.lignes; return [L.length, L.filter((l) => /\bsame\b/.test(l)).length, L.filter((l) => /nom partagé : aucune cible rattachable/.test(l)).length,
      L.filter((l) => /\bsame\b/.test(l) && /nom partagé/.test(l)).length, j.chemins.length].join("|"); })()' "5|2|2|2|0"
}

# ---------- « ailleurs sur ce poste » ----------
pi_fx() { # <nom> <json des entrées de claude agents> <code de sortie> : faux claude propre à ce cas
  PI_BIN="$WORK/pi-bin"; mkdir -p "$PI_BIN"; printf '%s' "$2" > "$WORK/pi-$1.json"; printf '%s' "$3" > "$WORK/pi-$1.rc"
  printf '#!/bin/sh\ncat "%s"\nexit "$(cat "%s" 2>/dev/null || echo 0)"\n' "$WORK/pi-$1.json" "$WORK/pi-$1.rc" > "$PI_BIN/claude"; chmod +x "$PI_BIN/claude"
}
pi_ent() { # <index> <cwd> : une entrée « vous attend » (état blocked), identifiant inventé
  printf '{"sessionId":"3f2c9a10-5b7e-4c1d-9a2e-0d4f6b8c1e%02d","kind":"interactive","pid":%d,"cwd":"%s","state":"blocked"}' "$1" "$((4000+$1))" "$2"
}
pi_cas() { # <nom> <json> <rc> <lab> : joue le scénario ailleurs ; sortie dans $WORK/pi-<nom>.out
  pi_fx "$1" "$2" "$3"; pi_page ailleurs "$4" "$WORK/pi-$1.out" "" PATH="$PI_BIN:$PATH"
}
# pi_sentinelles : poste et nom du lab voisin aléatoires, identifiants, titre ; PI_SENT = le JSON des sentinelles ; PI_FUITE_JSON = le faux claude correspondant
pi_sentinelles() {
  local r="$(printf '%04x%04x' $RANDOM $RANDOM)" id agents
  [ -d "$WORK/lab-fuite" ] || rg_lab "$WORK/lab-fuite"
  PI_POSTE="$WORK/poste-$r"; PI_LABV="atelier-$r"; mkdir -p "$PI_POSTE/$PI_LABV"; PI_POSTE="$(pi_rep "$PI_POSTE")"
  id="3f2c9a10-5b7e-4c1d-9a2e-$(printf '%04x%04x%04x' $RANDOM $RANDOM $RANDOM)"
  agents="[\"s0000000-aaaa-bbbb-cccc-$(printf '%04x%04x%04x' $RANDOM $RANDOM $RANDOM)\",\"s1000000-aaaa-bbbb-cccc-$(printf '%04x%04x%04x' $RANDOM $RANDOM $RANDOM)\"]"
  PI_SENT="{\"id\":\"$id\",\"titre\":\"TITRE-SECRET-$r\",\"chemin\":\"$PI_POSTE/$PI_LABV\",\"parent\":\"poste-$r\",\"lab\":\"$PI_LABV\",\"dossier\":\"$(pi_rep "$WORK/lab-fuite")\",\"marqueur\":\"$WORK/pi-marqueur\",\"agents\":$agents}"
  PI_FUITE_JSON="[{\"sessionId\":\"$id\",\"kind\":\"interactive\",\"pid\":4099,\"cwd\":\"$PI_POSTE/$PI_LABV\",\"state\":\"blocked\",\"name\":\"TITRE-SECRET-$r\",\"title\":\"TITRE-SECRET-$r\"}]"
}
# pi_fuite <fichier> : le témoin de non-fuite sur un serveur frais (module muté si COCKPIT_MODULE est posé) ; sortie JSON dans <fichier>
pi_fuite() {
  [ -d "$WORK/lab-fuite" ] || rg_lab "$WORK/lab-fuite"
  pi_sentinelles; pi_fx fx-fuite "$PI_FUITE_JSON" 0
  pi_page fuite "$WORK/lab-fuite" "$1" "$PI_SENT" PATH="$PI_BIN:$PATH"
}
PI_SONDE_FUITE='(function(){ const f = Object.keys(j.trouve).filter((k) => j.trouve[k].length); return (f.length ? f.join(",") : "aucune"); })()'

# RG18 (correctifs de fin de phase, juge design) : la page à 1 440 px et le pied, MESURÉS (CDP) contre les jetons par sonde ; sans Chrome : NON VÉRIFIÉ
rg_RG18_design() {
  rg_chrome || return 0
  pi_lab_arbres; pi_page design "$WORK/lab-arb" "$WORK/pi-design.json" ""
  local D="$WORK/pi-design.json"
  pi_ok "RG18.1 — sur Équipe à 1 440 px, le panneau latéral du moteur (« Base de code », Santé) n'est pas affiché" "$D" 'j.page.panneau' "false"
  pi_ok "RG18.2 — le nom est le bouton d'ouverture ; une feuille et une session seule n'ont aucun caret, une ligne reste de 44 à 56 px" "$D" \
    '[j.page.nomOuvre, j.page.caretFeuille, j.page.caretSeule, j.page.hFeuille >= 44 && j.page.hFeuille <= 56, j.page.hSeule >= 44 && j.page.hSeule <= 56, j.page.hParent >= 44 && j.page.hParent <= 56].join("|")' "true|0|0|true|true|true"
  pi_ok "RG18.2 — le parent qui a des enfants porte un seul caret de 44 × 44, nommé « Sous-agents, 2 »" "$D" '[j.page.caretParent, j.page.caretTaille, j.page.caretLabel].join("|")' "1|44x44|Sous-agents, 2"
  pi_ok "RG18.2 — le caret replie puis rouvre les sous-agents (aria-expanded suit)" "$D" '[j.replie.exp, j.replie.fils, j.rouvert.exp, j.rouvert.fils !== "none"].join("|")' "false|none|true|true"
  pi_ok "RG18.3 — le caret est nu : de la couleur du nom de la ligne, jamais de la teinte d'état" "$D" 'j.page.couleurCaret' "true"
  pi_ok "RG18.4 — le détail en flux : --raise, --r-ctl, --inset-box, gap --sp-8 (relevés contre une sonde aux jetons)" "$D" '[j.detail.fond, j.detail.rayon, j.detail.marge, j.detail.ecart].join("|")' "true|true|true|true"
  pi_ok "RG18.5 — arbres de travail : lignes de 44 à 56 px, repère d'ouverture dans le résumé (couleur du texte), pastilles sans fond" "$D" \
    '[j.pied.hauteurs.length, j.pied.hauteurs.every((x) => x >= 44 && x <= 56), j.pied.marque, j.pied.couleurMarque, j.pied.pastilles.length > 0 && j.pied.pastilles.every((c) => c === "rgba(0, 0, 0, 0)")].join("|")' "3|true|1|true|true"
  pi_ok "RG18.6 — l'arbre a son fil de 1 px (--fil) et son coude de rayon 8" "$D" '[j.arbre.contenu, j.arbre.largeur, j.arbre.couleur, j.arbre.bas, j.arbre.rayon].join("|")' "true|1px|true|1px|8px"
  assert_eq "RG18.7 — ni tiret cadratin ni repli « — » dans la ligne d'arbre (spec § 16.12), ni dans le rendu" \
    "$(grep -c "'—'" "$UI/72-vf-regie-pied.js" 2>/dev/null)|$(pi_g "$D" 'j.pied.tiret')" "0|false"
}

rg_RG13_page() {
  # ---------- RG13.35 (sans navigateur) : la réponse de la route n'a que les clés déclarées au contrat ----------
  cat > "$AUX/pi-contrat.mjs" <<'JS'
// pi-contrat.mjs <interface.json> <réponse json> : « ok » si chaque entrée de `ailleurs` n'a que des clés du bloc cockpit-ailleurs@1 et aucune clé interdite ; sinon « faux:… »
import fs from 'node:fs';
const c = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')).schemas?.['vibeflow/cockpit-ailleurs@1'] ?? JSON.parse(fs.readFileSync(process.argv[2], 'utf8'))['vibeflow/cockpit-ailleurs@1'] ?? null;
let r; try { r = JSON.parse(fs.readFileSync(process.argv[3], 'utf8')); } catch { console.log('faux:réponse illisible'); process.exit(0); }
if (!c) { console.log('faux:bloc absent'); process.exit(0); }
const permis = new Set(c.entree.requis), pb = [];
if (r.schema !== 'vibeflow/cockpit-ailleurs@1') pb.push('schéma ' + r.schema);
if (!Array.isArray(r.ailleurs) || r.ailleurs.length === 0) pb.push('liste vide ou nulle (témoin positif manquant)');
for (const e of r.ailleurs || []) for (const k of Object.keys(e)) { if (!permis.has(k)) pb.push('clé non déclarée ' + k); if (c.interdits.includes(k)) pb.push('clé interdite ' + k); }
console.log(pb.length ? 'faux:' + pb.join(',') : 'ok');
JS
  local L="$WORK/lab-page"; [ -d "$L" ] || rg_lab "$L"
  pi_sentinelles; pi_fx contrat "[$(pi_ent 10 "$PI_POSTE/$PI_LABV")]" 0; rg_init
  COCKPIT_SORTIE="$L/.vibeflow/cockpit" cockpit_lancer "$L" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" PATH="$PI_BIN:$PATH"
  local i ok=ko; for i in 1 2 3 4 5 6 7 8; do cockpit_get /api/vf/ailleurs > "$WORK/pi-contrat.body" 2> /dev/null; grep -q '"lab"' "$WORK/pi-contrat.body" && { ok=oui; break; }; sleep 0.5; done
  RG_PID="${VF_PID:-}"; rg_arreter
  assert_eq "RG13.35 — la réponse de /api/vf/ailleurs n'a que des clés déclarées au bloc vibeflow/cockpit-ailleurs@1 du contrat, aucune clé interdite (liste lue : $ok)" "$(node "$AUX/pi-contrat.mjs" "$SCRIPTS/vf-cockpit-interface.json" "$WORK/pi-contrat.body")" "ok"

  rg_chrome || return 0
  local P="$PI_POSTE"; mkdir -p "$P/atelier-x" "$P/alpha" "$P/beta" "$P/gamma" "$P/delta"
  pi_cas un "[$(pi_ent 10 "$P/atelier-x")]" 0 "$WORK/lab-page"
  pi_cas quatre "[$(pi_ent 11 "$P/alpha"),$(pi_ent 12 "$P/beta"),$(pi_ent 13 "$P/gamma"),$(pi_ent 14 "$P/delta")]" 0 "$WORK/lab-page"
  pi_cas perso "[$(pi_ent 15 "$HOME")]" 0 "$WORK/lab-page"
  pi_cas echec "[$(pi_ent 16 "$P/atelier-x")]" 1 "$WORK/lab-page"
  pi_ok "RG13.30 — une session « vous attend » dans le lab voisin « atelier-x » : « Ailleurs sur ce poste : 1 session vous attend, dans « atelier-x ». »" "$WORK/pi-un.out" 'j.ligne' "Ailleurs sur ce poste : 1 session vous attend, dans « atelier-x »."
  pi_ok "RG13.31 — quatre labs : trois noms puis « et 1 autre » (pluriel des sessions) ; dossier personnel : « un autre dossier »" "$WORK/pi-quatre.out" 'j.ligne' "Ailleurs sur ce poste : 4 sessions vous attendent, dans « alpha », « beta », « delta » et 1 autre."
  pi_ok "RG13.31 — dossier personnel : le nom générique" "$WORK/pi-perso.out" 'j.ligne' "Ailleurs sur ce poste : 1 session vous attend, dans « un autre dossier »."
  pi_ok "RG13.32 — lecture officielle en échec : aucune ligne, jamais « 0 »" "$WORK/pi-echec.out" '(j.ligne === null) + "|" + !/Ailleurs|0 session/.test(j.section)' "true|true"
  pi_ok "RG13.33 — le titre du document ne compte pas la session d'ailleurs (préface « (N) » absente)" "$WORK/pi-un.out" '(typeof j.titre === "string" && j.titre.length > 0) + "|" + !/^\(\d+\)/.test(j.titre) + "|" + !/vous attend/.test(j.titre)' "true|true|true"

  pi_fuite "$WORK/pi-fuite.json"
  local E34='(j.positif ? "ligne" : "sans-ligne") + "|" + j.nomDansPage + "|" + '"$PI_SONDE_FUITE"' + "|" + j.fichiers.serveur + "|" + (j.hellos >= 2) + "|" + j.transcript.aTranscript'
  pi_ok "RG13.34 — précondition (la page affiche la ligne et le nom du lab) puis aucune sentinelle (identifiant, titre, chemin, dossier parent, nom du lab) dans l'export, les fichiers neufs sous le lab (server.json parcouru), les trames (hello d'une seconde connexion compris), who, l'état, le journal, localStorage, sessionStorage ni le titre ; aucun transcript" "$WORK/pi-fuite.json" "$E34" "ligne|true|aucune|true|true|false"
  # ---------- un mutant par support de fuite ----------
  pi_mutant_fuite() { # <nom> <libellé> <module muté : exporte COCKPIT_MODULE> : la sonde de fuite doit nommer au moins un support
    local nom="$1" lib="$2" f="$WORK/pi-mut-$1.json" got
    pi_fuite "$f"; got="$(pi_g "$f" "$PI_SONDE_FUITE")"; unset COCKPIT_MODULE
    if [ "$got" != "aucune" ] && [ "${got#ERR:}" = "$got" ]; then echo "  ✅ PASS — M-$nom — $lib (mutant tué : fuite par $got)"; PASS=$((PASS+1))
    else echo "  ❌ FAIL — M-$nom — $lib (mutant survivant)"; echo "     attendu: [une fuite nommée]"; echo "     obtenu:  [$got]"; FAIL=$((FAIL+1)); fi
  }
  if cockpit_module_muter_page "pi-stock" 's@donneesAilleurs = Array.isArray(j.ailleurs) ? j.ailleurs : null;@donneesAilleurs = Array.isArray(j.ailleurs) ? (sessionStorage.setItem("vf-m", JSON.stringify(j.ailleurs)), j.ailleurs) : null;@' > /dev/null 2>&1
  then pi_mutant_fuite AILLEURS-PAGE-STOCKAGE "le pied garde la réponse dans sessionStorage"
  else unset COCKPIT_MODULE; assert_eq "M-AILLEURS-PAGE-STOCKAGE — le pied garde la réponse dans sessionStorage (ancre)" "ancre absente" "muté"; fi
  if cockpit_module_muter "pi-flux" vf-cockpit-server.mjs 's@JSON.stringify(snap)}@JSON.stringify({ ...snap, ailleurs: ailleurs(os.homedir(), { racines: [\"/nulle-part-un\"] }) })}@; s@^import fs from .node:fs.;@import fs from \"node:fs\"; import os from \"node:os\"; import { ailleurs } from \"./vf-cockpit-etat-officiel.mjs\";@' > /dev/null 2>&1
  then pi_mutant_fuite AILLEURS-FLUX "le direct ajoute la liste au hello"
  else unset COCKPIT_MODULE; assert_eq "M-AILLEURS-FLUX — le direct ajoute la liste au hello (ancre)" "ancre absente" "muté"; fi
}

rg_RG14_fr() {
  rg_chrome || return 0
  pi_page fr "$WORK/lab-page" "$WORK/pi-fr.json" ""
  pi_ok "RG14.20 — une tâche d'agent « Files » et un rôle « Health » restent tels quels dans la régie" "$WORK/pi-fr.json" 'j.files + "|" + j.health' "true|true"
  pi_ok "RG14.21 — aucun texte visible de section#vf-equipe hors données n'est une clé anglaise du dictionnaire (bloc des arbres ouvert)" "$WORK/pi-fr.json" 'j.anglais.length + "|" + j.anglais.join(";")' "0|"
}

rg_RG16_export() {
  rg_chrome || return 0
  [ -s "$WORK/pi-fuite.json" ] || { [ -d "$WORK/lab-fuite" ] || rg_lab "$WORK/lab-fuite"; pi_fuite "$WORK/pi-fuite.json"; }
  pi_ok "RG16.20 — précondition (la ligne « ailleurs » est affichée, des lignes d'agents aussi, les motifs trouvent le DOM vivant) puis l'export demandé depuis la page Équipe ne contient ni balisage de la régie (id vf-equipe, classes vf-rg-, data-vf-cle) ni aucun identifiant d'agent de la fixture" "$WORK/pi-fuite.json" \
    '(j.positif ? 1 : 0) + "|" + (j.lignes >= 1) + "|" + j.export.statut + "|" + j.export.temoin + "|" + j.export.vfEquipe + "|" + j.export.cle + "|" + j.export.agents.length' "1|true|200|true|false|false|0"
}
