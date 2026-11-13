# regie-rg-modele.sh — fragment du plan 73-04, SOURCÉ par test-cockpit-regie.sh (ne définit que des fonctions) : modèle pur de la régie, joué en vm (vm-regie.mjs), sans navigateur.
#   RG0_ordre_modele (ordre de chargement sur la sortie assemblée) · RG1_modele (sections, clés, vides, sous-titre, REGI-01) · RG2_modele (liste blanche : deux formes, REGI-02)
#   RG4_modele (À vous, REGI-04) · RG5_modele (tri et libellés d'impact, REGI-05) · RG6_modele (verrou : liste blanche et ligne de mission, REGI-06)
#   RG7_modele (marques de gouvernance, REGI-07) · RG8_modele (ligne 2) · RG9_modele (états et seuils, REGI-09) · RG10_modele (attend ses agents, REGI-10)
#   RG11_modele (à relire, REGI-11) · RG14_modele (feuille, REGI-14).
# Mutants (M-<NOM>, une assertion chacun) : seulement pour une garde (liste blanche du verrou, clé, orphelin sans action, glyphes uniques) et pour les seuils nommés au plan.
# Fixtures : noms et identifiants inventés ; sentinelles de chemin construites à l'exécution. Espaces insécables rendus en espaces simples par le harnais (sauf RG9.8).

RGM_NOW=1000000000000
RGM_CX='{"now":1000000000000,"recuA":1000000000000,"fenetre":900,"lus":null,"nonCommite":{},"missions":[]}'
RGM_CXN='{"now":1000000000000,"recuA":1000000000000,"fenetre":null,"lus":null,"nonCommite":{},"missions":[]}'
RGM_W5='{"workers":[
 {"kind":"session","id":"s-attend","etat":"attend","titre":"Atelier alpha","tree":".","ageS":840,"retient":{"n":4,"portee":"noeuds"}},
 {"kind":"session","id":"s-pilote","etat":"actif","titre":"Pilote","tree":".","ageS":30},
 {"kind":"subagent","id":"a-un","etat":"actif","parent":"s-pilote","role":"vf-coder","task":"Écrire le modèle","ageS":60,"dureeS":300,"tree":"."},
 {"kind":"subagent","id":"a-deux","etat":"en-attente","parent":"s-pilote","role":"vf-auditer","task":"Auditer","ageS":10,"tree":"."},
 {"kind":"session","id":"s-veille","etat":"au-repos","titre":"Veille","tree":".","ageS":2700},
 {"kind":"subagent","id":"a-fini","etat":"termine","parent":"s-pilote","role":"vf-reviewer","task":"Relire","ageS":180,"dureeS":1740,"tree":"."}],
 "phasesHumaines":[{"phase":"7","ws":"fiabilite","ref":"n:ph-7"}]}'

g() { G "$@" 2>/dev/null; }
rgm_modele() { printf '{"fn":"modele","args":[%s,%s,%s]}' "$1" "${2:-null}" "${3:-$RGM_CX}"; }
rgm_appel() { printf '{"fn":"%s","args":%s}' "$1" "$2"; }
rgm_json() { local s="[" sep="" x; for x in "$@"; do s="$s$sep$x"; sep=","; done; printf '%s]' "$s"; }
rgm_play() { node "$TESTS_DIR/vm-regie.mjs" "$1" "$2" ${4:+"$4"} > "$3" 2>&1; return 0; }   # rgm_play <dossier ui> <scénario> <sortie> [brut]
# rgm_lock <owner> <scope> <ws> <leaseS|null> <stale> <progressAgeS|null> [phase] [ageS] : un verrou projeté (A15) enveloppé comme le flux `lock`
rgm_lock() { printf '{"seq":1,"at":"t","verrous":{"etat":"lue","plat":false,"liste":[{"ws":"%s","scope":"%s","phase":"%s","step":"exec","tenu":true,"stale":%s,"ageS":%s,"ttl":1800,"progressAgeS":%s,"owner":"%s","leaseS":%s}]}}' "$3" "$2" "${7:-73}" "$5" "${8:-180}" "$6" "$1" "$4"; }
rgm_ev() { rgm_appel etatVivant "[{\"kind\":\"$1\",\"etat\":\"$2\",$3},$4]"; }   # rgm_ev <kind> <etat> <champs JSON> <ctx> (bash 3.2 : jamais de \" dans un $( ) entre guillemets)
rgm_sess() { printf '{"workers":[{"kind":"session","id":"sess-1","etat":"actif","titre":"Atelier alpha","tree":".","ageS":30}]}'; }

rg_RG0_ordre_modele() {
  cat > "$AUX/ordre.mjs" <<'JS'
// ordre.mjs <html> <nom du modèle> : « ok » si le repère du modèle est unique, après 71 et 72-vf-equipe, avant 73 et tout 74-, et le style présent une fois ; « faux:… » ou « illisible:… » sinon
import fs from 'node:fs';
const [, , f, nom] = process.argv;
let t; try { t = fs.readFileSync(f, 'utf8'); } catch { console.log('illisible:' + f); process.exit(0); }
const m = (n) => `/* ui/${n} */`, n = (s) => t.split(s).length - 1, at = (s) => t.indexOf(s);
const pb = [];
if (n(m(nom)) !== 1) pb.push(`modèle ×${n(m(nom))}`);
if (n(m('72-vf-regie-style.js')) !== 1) pb.push(`style ×${n(m('72-vf-regie-style.js'))}`);
const i = at(m(nom));
for (const av of ['71-vf-equipe-rendu.js', '72-vf-equipe.js']) if (!(at(m(av)) >= 0 && i > at(m(av)))) pb.push(`pas après ${av}`);
if (!(at(m('73-vf-tiroir-travail.js')) > i)) pb.push('pas avant 73');
const k = t.indexOf('/* ui/74-'); if (k >= 0 && !(k > i)) pb.push('pas avant 74-');
console.log(pb.length ? 'faux:' + pb.join(',') : 'ok');
JS
  local L="$WORK/ord-lab"; mkdir -p "$L/src" "$L/.planning"; printf 'x\n' > "$L/src/u.js"; printf '## Phases\n\n- [ ] **Phase 1: Socle** - jet\n' > "$L/.planning/ROADMAP.md"
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/ord-build.out" 2>&1
  local r="" f; for f in index.html project.html; do r="$r$f=$(node "$AUX/ordre.mjs" "$L/.vibeflow/cockpit/$f" 72-vf-regie-modele.js 2>&1) "; done
  assert_eq "RG0.10 — ordre de chargement sur la sortie assemblée (modèle unique, après 71 et 72-vf-equipe, avant 73 et 74-)" "$r" "index.html=ok project.html=ok "
  if [ ! -f "$UI/72-vf-regie-modele.js" ]; then assert_eq "M-ORDRE-UI — modèle présent pour muter" "absent" "présent"; return 0; fi
  local M="$WORK/mu"; rm -rf "$M"; mkdir -p "$M/skills"; cp -R "$SCRIPTS" "$M/scripts"; rm -rf "$M/scripts/tests"; cp -R "$SCRIPTS/../skills/cockpit-moteur" "$M/skills/cockpit-moteur"
  mv "$M/skills/cockpit-moteur/assets/ui/72-vf-regie-modele.js" "$M/skills/cockpit-moteur/assets/ui/70a-vf-regie-modele.js"
  local L2="$WORK/ord-lab2"; mkdir -p "$L2/src" "$L2/.planning"; printf 'x\n' > "$L2/src/u.js"; printf '## Phases\n\n- [ ] **Phase 1: Socle** - jet\n' > "$L2/.planning/ROADMAP.md"
  node "$M/scripts/vf-cockpit-build.mjs" "$L2" --quiet > "$WORK/ord-build2.out" 2>&1
  assert_has "M-ORDRE-UI — modèle renommé 70a-… : le témoin d'ordre rougit (mutant tué)" "$(node "$AUX/ordre.mjs" "$L2/.vibeflow/cockpit/index.html" 72-vf-regie-modele.js 2>&1)" "faux:"
}

rg_RG1_modele() {
  local sc="$WORK/sc1.json" o="$WORK/o1.json"
  rgm_json "$(rgm_modele "$RGM_W5")" \
    "$(rgm_modele '{"workers":[{"kind":"session","id":"s1","etat":"attend","titre":"Seule","tree":".","ageS":5}]}')" \
    "$(rgm_modele '{"workers":[{"kind":"session","id":"s1","etat":"actif","titre":"Seule","tree":".","ageS":5}]}')" \
    "$(rgm_modele '{"workers":[]}')" > "$sc"
  rgm_play "$UI" "$sc" "$o"
  assert_eq "RG1.1 — quatre sections dans l'ordre, titres exacts" "$(g "$o" 'j[0].sections.map(s=>s.titre).join("|")')" "À vous|Au travail|Terminé, à relire|Au repos"
  assert_eq "RG1.1 — compteurs = lignes (agents ; les lignes de mission ne comptent pas)" "$(g "$o" 'j[0].sections.map(s=>s.compte+"/"+s.lignes.filter(l=>l.kind!=="mission").length).join(" ")')" "2/2 4/4 1/1 1/1"
  assert_eq "RG1.1 — sous-titre : agents distincts en vie, attentes, à relire" "$(g "$o" 'j[0].entete.sousTitre')" "5 agents · 2 vous attendent · 1 à relire"
  assert_eq "RG1.1 — singuliers, un agent seul, zéro agent" "$(g "$o" 'j[1].entete.sousTitre+"|"+j[2].entete.sousTitre+"|"+j[3].entete.sousTitre')" "1 agent · 1 vous attend|1 agent|Aucun agent en vie"
  assert_eq "RG1.2 — un agent qui attend : deux lignes, clés section:identifiant" "$(g "$o" '[0,1].map(i=>j[0].sections[i].lignes.find(l=>l.id==="s-attend").cle).join("|")')" "a-vous:s-attend|au-travail:s-attend"
  assert_eq "RG1.2 — clés toutes distinctes ; la ligne de l'arbre ne répète pas l'impact" "$(g "$o" '(()=>{const c=j[0].sections.flatMap(s=>s.lignes.map(l=>l.cle)); return (new Set(c).size===c.length)+"|"+j[0].sections[1].lignes.find(l=>l.id==="s-attend").detail+"|"})()')" "true||"
  assert_eq "RG1.3 — sections vides : leurs textes" "$(g "$o" 'j[3].sections.map(s=>s.vide).join("|")')" "Rien ne vous attend.|Personne ne travaille en ce moment.|Aucun rapport à relire.|Aucune session au repos."
  assert_eq "RG1.3 — aucun agent : l'état de la page le dit ; avec des agents, il se tait" "$(g "$o" 'j[3].etatPage+"|"+j[0].etatPage+"|"')" "Aucun agent dans les dernières 24 h.||"
  if [ -f "$UI/72-vf-regie-modele.js" ]; then
    rg_mutant "CLE-ID-SEUL" "clé = identifiant seul" "$UI" "72-vf-regie-modele.js" 'cle: `${sec}:${w.id}`' 'cle: w.id' rgm_sonde_cle "a-vous:s-attend|au-travail:s-attend"
  else assert_eq "M-CLE-ID-SEUL — modèle présent pour muter" "absent" "présent"; fi
}
rgm_sonde_cle() { rgm_play "$1" "$WORK/sc1.json" "$WORK/o1.mut"; g "$WORK/o1.mut" '[0,1].map(i=>j[0].sections[i].lignes.find(l=>l.id==="s-attend").cle).join("|")'; }

rg_RG2_modele() {
  local sc="$WORK/sc2.json" o="$WORK/o2.json"
  local brut='{"ws":"fiabilite","scope":"mission","phase":"73","step":"exec","present":true,"stale":false,"age_seconds":180,"ttl":1800,"progress_age_seconds":600,"children_running":2,"owner":"sess-1","lease_seconds":840,"session_ids":["x"]}'
  local proj='{"ws":"fiabilite","scope":"mission","phase":"73","step":"exec","tenu":true,"stale":false,"ageS":180,"ttl":1800,"progressAgeS":600,"childrenRunning":2,"owner":"sess-1","leaseS":840}'
  local env="{\"seq\":1,\"at\":\"t\",\"verrous\":{\"etat\":\"lue\",\"plat\":false,\"liste\":[$proj]}}"
  rgm_json "$(rgm_appel verrouBlanc "[$brut]")" "$(rgm_appel verrouBlanc "[$proj]")" "$(rgm_appel verrous "[[$brut]]")" "$(rgm_appel verrous "[$env]")" > "$sc"
  rgm_play "$UI" "$sc" "$o"
  assert_eq "RG2.0 — la forme brute et la forme projetée donnent le même objet" "$(g "$o" 'j[0].leaseS===840 && JSON.stringify(j[0])===JSON.stringify(j[1])')" "true"
  assert_eq "RG2.0 — verrous() : mêmes listes pour les deux formes, un verrou tenu" "$(g "$o" '(JSON.stringify(j[2])===JSON.stringify(j[3]))+"|"+j[2].length+"|"+j[0].leaseS+"|"+j[0].progressAgeS')" "true|1|840|600"
}

rg_RG4_modele() {
  local sc="$WORK/sc4.json" o="$WORK/o4.json" w
  w='{"fenetreStallS":900,"workers":[
 {"kind":"session","id":"s-att","etat":"attend","titre":"Attend","tree":".","ageS":500},
 {"kind":"session","id":"p-term","etat":"termine","titre":"Parti","tree":".","ageS":4000},
 {"kind":"subagent","id":"o-orph","etat":"actif","orphan":true,"parent":"p-term","role":"vf-coder","task":"Orphelin","ageS":100,"dureeS":700,"tree":"."},
 {"kind":"session","id":"s-act","etat":"actif","titre":"Acteur","tree":".","ageS":5},
 {"kind":"subagent","id":"a-susp","etat":"actif","parent":"s-act","role":"vf-coder","task":"Suspect","ageS":1080,"tree":"."},
 {"kind":"session","id":"s-rep","etat":"au-repos","titre":"Repos","tree":".","ageS":900},
 {"kind":"subagent","id":"f-fin","etat":"termine","parent":"s-act","role":"vf-reviewer","task":"Fini","ageS":60,"dureeS":10,"tree":"."}],
 "phasesHumaines":[{"phase":"7","ws":"fiabilite","ref":"n:ph-7"}]}'
  rgm_json "$(rgm_modele "$w")" "$(rgm_appel aVous "[$w]")" > "$sc"
  rgm_play "$UI" "$sc" "$o"
  assert_eq "RG4.4 — À vous : la session qui attend et la ligne de phase, ni orphelin, ni suspect, ni repos, ni terminé" "$(g "$o" 'j[0].sections[0].lignes.map(l=>l.cle).join("|")')" "a-vous:s-att|a-vous:phase:fiabilite:7"
  assert_eq "RG4.4 — la ligne de phase : nom, lien vers la carte, genre, aucune action" "$(g "$o" '(()=>{const l=j[0].sections[0].lignes[1]; return [l.nom,l.lien,l.kind,l.action,l.mot].map(String).join("|")})()')" "Phase 7 : vérification humaine demandée|project.html#r=n%3Aph-7|phase|null|vous attend"
  assert_eq "RG4.4 — aVous() compte les mêmes lignes" "$(g "$o" 'j[1]')" "2"
}

RGM_W55='{"workers":[
 {"kind":"session","id":"a","etat":"attend","titre":"Bêta","tree":".","ageS":100,"retient":{"n":1,"portee":"noeuds"}},
 {"kind":"session","id":"b","etat":"attend","titre":"Gamma","tree":".","ageS":50,"retient":{"n":4,"portee":"noeuds"}},
 {"kind":"session","id":"c","etat":"attend","titre":"Delta","tree":".","ageS":300},
 {"kind":"session","id":"d","etat":"attend","titre":"Epsilon","tree":".","ageS":900,"retient":{"n":0,"portee":"noeuds"}},
 {"kind":"session","id":"e","etat":"attend","titre":"Zêta","tree":".","ageS":500,"retient":{"n":4,"portee":"noeuds"}}]}'
rg_RG5_modele() {
  local sc="$WORK/sc5.json" o="$WORK/o5.json" w
  w='{"workers":[
 {"kind":"session","id":"x1","etat":"attend","titre":"Un","tree":".","ageS":1,"retient":{"n":4,"portee":"noeuds"}},
 {"kind":"session","id":"x2","etat":"attend","titre":"Deux","tree":".","ageS":1,"retient":{"n":1,"portee":"noeuds"}},
 {"kind":"session","id":"x3","etat":"attend","titre":"Trois","tree":".","ageS":1,"retient":{"n":3,"portee":"mission"}},
 {"kind":"session","id":"x4","etat":"attend","titre":"Quatre","tree":".","ageS":1,"retient":{"n":0,"portee":"noeuds"}},
 {"kind":"session","id":"x5","etat":"attend","titre":"Cinq","tree":".","ageS":1}]}'
  rgm_json "$(rgm_modele "$RGM_W55")" "$(rgm_modele "$w")" \
    "$(rgm_appel trierAVous '[[{"id":"z2","nom":"n","impact":2,"age":5},{"id":"z1","nom":"n","impact":2,"age":5},{"id":"a9","nom":"m","impact":2,"age":5}]]')" > "$sc"
  rgm_play "$UI" "$sc" "$o"
  assert_eq "RG5.5 — jeu de la UI-SPEC : impact 4, 1, inconnu, 0 ; deux impacts égaux départagés par l'ancienneté" "$(g "$o" 'j[0].sections[0].lignes.map(l=>l.id).join(",")')" "e,b,a,c,d"
  assert_eq "RG5.5 — égalité complète : le nom, puis l'identifiant" "$(g "$o" 'j[2].map(l=>l.id).join(",")')" "a9,z1,z2"
  assert_eq "RG5.6 — libellés d'impact" "$(g "$o" 'j[1].sections[0].lignes.slice().sort((p,q)=>p.id<q.id?-1:1).map(l=>l.id+":"+l.detail).join("|")')" "x1:retient 4 nœuds|x2:retient 1 nœud|x3:retient toute la mission · 3 nœuds|x4:ne retient rien|x5:impact inconnu"
  if [ -f "$UI/72-vf-regie-modele.js" ]; then
    rg_mutant "IMPACT-TRI" "rangs 2 et 3 permutés" "$UI" "72-vf-regie-modele.js" '(l.impact == null ? 1 : l.impact > 0 ? 0 : 2)' '(l.impact == null ? 2 : l.impact > 0 ? 0 : 1)' rgm_sonde_tri "e,b,a,c,d"
  else assert_eq "M-IMPACT-TRI — modèle présent pour muter" "absent" "présent"; fi
}
rgm_sonde_tri() { rgm_play "$1" "$WORK/sc5.json" "$WORK/o5.mut"; g "$WORK/o5.mut" 'j[0].sections[0].lignes.map(l=>l.id).join(",")'; }

rg_RG6_modele() {
  local CH LONG sc="$WORK/s61.json" o="$WORK/o61.json" e
  CH="$(printf '%s' '/Us' 'ers/quidam/lab/locks/x')"; LONG="$(printf 'o%.0s' $(seq 1 120))"
  e="{\"ws\":\"fiabilite\",\"scope\":\"mission\",\"phase\":\"73\",\"step\":\"exec\",\"present\":true,\"age_seconds\":10,\"lease_seconds\":840,\"owner\":\"sess-1\",\"session_ids\":[\"SENT-SID-1\",\"SENT-SID-2\"],\"dir\":\"$CH\",\"emplacement\":\"$CH/fichier\",\"inconnu\":\"SENT-INCONNU\"}"
  local e2="{\"present\":true,\"owner\":\"$LONG\",\"step\":\"$LONG\"}" e3="{\"present\":true,\"owner\":\"$CH\",\"step\":\"C:\\\\partage\"}"
  rgm_json "$(rgm_appel verrouBlanc "[$e]")" "$(rgm_appel verrouBlanc "[$e2]")" "$(rgm_appel verrouBlanc "[$e3]")" \
    "$(rgm_appel verrouBlanc '[{"present":true,"owner":"ab\u0007c‮d​e","step":"e\u0000t"}]')" > "$sc"
  rgm_play "$UI" "$sc" "$o"
  assert_eq "RG6.1 — entrée à sentinelles : aucune ne sort (identifiants de session, chemins, emplacement, clé brute, clé inconnue)" "$(g "$o" 'j[0].ws==="fiabilite" && !/SENT|quidam|session_ids|lease_seconds|emplacement|"dir"/.test(JSON.stringify(j[0]))')" "true"
  assert_eq "RG6.1 — treize clés exactement, leaseS lu depuis lease_seconds" "$(g "$o" 'Object.keys(j[0]).join(",")+"|"+j[0].leaseS')" "ws,scope,phase,step,tenu,stale,ageS,ttl,progressAgeS,owner,childrenRunning,leaseS,sansSession|840"
  assert_eq "RG6.1 — owner et étape de 120 caractères : bornés à 80" "$(g "$o" 'j[1].owner.length+"|"+j[1].step.length')" "80|80"
  assert_eq "RG6.1 — owner à forme de chemin absolu (ou de partage) : vide" "$(g "$o" 'JSON.stringify([j[2].owner,j[2].step])')" '["",""]'
  assert_eq "RG6.1 — caractères de contrôle et U+202E (classe Cf) retirés" "$(g "$o" 'j[3].owner+"|"+j[3].step')" "abcde|et"
  rgm_forme_cas
  if [ -f "$UI/72-vf-regie-modele.js" ]; then
    rg_mutant "VERROU-ENTREE-BRUTE" "l'entrée recopiée entière" "$UI" "72-vf-regie-modele.js" 'const o = { ws: libre(e.ws),' 'const o = { ...e, ws: libre(e.ws),' rgm_sonde_verrou "false|80|\"\"|abcde"
    rg_mutant "VERROU-SESSION-IDS" "la liste d'identifiants de session admise" "$UI" "72-vf-regie-modele.js" "sansSession: typeof e.sansSession === 'boolean' ? e.sansSession : null };" "sansSession: typeof e.sansSession === 'boolean' ? e.sansSession : null, session_ids: e.session_ids };" rgm_sonde_verrou "false|80|\"\"|abcde"
    rg_mutant "VERROU-CHEMIN" "refus du chemin absolu retiré" "$UI" "72-vf-regie-modele.js" '/^(\/|\\|[A-Za-z]:[\\/]|~[\\/])/.test(s)' 'false' rgm_sonde_verrou "false|80|\"\"|abcde"
    rg_mutant "VERROU-OWNER-SANS-BORNE" "borne de 80 retirée" "$UI" "72-vf-regie-modele.js" ': s.slice(0, n)' ': s' rgm_sonde_verrou "false|80|\"\"|abcde"
  else assert_eq "M-VERROU-* — modèle présent pour muter" "absent" "présent"; fi
  local sc2="$WORK/sc62.json" o2="$WORK/o62.json" L1 L0 LD LF
  L1="$(rgm_lock sess-1 mission fiabilite 840 false null)"; L0="$(rgm_lock sess-1 mission fiabilite null false null)"
  LD="$(rgm_lock sess-1 depot '' 840 false null)"; LF="$(rgm_lock aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee mission fiabilite 840 false null)"
  rgm_json "$(rgm_modele "$(rgm_sess)" "$L1")" "$(rgm_modele "$(rgm_sess)" "$L0")" "$(rgm_modele "$(rgm_sess)" "$LF")" "$(rgm_modele "$(rgm_sess)" "$LD")" > "$sc2"
  rgm_play "$UI" "$sc2" "$o2"
  local m='.sections[1].lignes.filter(l=>l.kind==="mission").map(l=>l.nom).join("|")'
  assert_eq "RG6.2 — ligne de mission : session nommée, étape, tenu depuis (leaseS), dernier signe (ageS)" "$(g "$o2" "j[0]$m")" "verrou : Atelier alpha · exec · tenu depuis 14 min · dernier signe il y a 3 min"
  assert_eq "RG6.2 — leaseS null : « dernier signe » seul, aucune durée devinée" "$(g "$o2" "j[1]$m")" "verrou : Atelier alpha · exec · dernier signe il y a 3 min"
  assert_eq "RG6.2 — owner hors des sessions : forme courte" "$(g "$o2" "j[2]$m")" "verrou : aaaaaaaa · exec · tenu depuis 14 min · dernier signe il y a 3 min"
  assert_eq "RG6.2 — verrou de dépôt : ligne d'en-tête seulement, aucune ligne de mission" "$(g "$o2" 'j[3].entete.verrouDepot.texte+"|"+j[3].sections[1].lignes.filter(l=>l.kind==="mission").length+"|"+(j[0].entete.verrouDepot===null)')" "Verrou du dépôt : Atelier alpha · exec · tenu depuis 14 min · dernier signe il y a 3 min|0|true"
}
# Forme admise (T-73-16, audit 73-04) : owner et étape n'ont pas de séparateur ; ws, phase, scope, dag suivent une grammaire stricte.
# rgm_forme_sc <sortie> : un appel verrouBlanc par valeur, sur les cinq champs.
RGM_OWNERS='a/Users/quidam/lab|lab/locks/x|file:///Users/quidam/x|../../etc/passwd|~quidam|a b|..|release-bump|exec-73|vf-dev-manager-p73|3f9a0c1e7b'
rgm_forme_un() { local e; e="[{\"present\":true,$1}]"; printf '%s' "$(rgm_appel verrouBlanc "$e")"; }   # bash 3.2 : jamais de \" dans un $( ) entre guillemets
rgm_forme_sc() {
  local IFS='|' a=() v w
  for v in $RGM_OWNERS; do w="\"owner\":\"$v\",\"step\":\"$v\""; a+=("$(rgm_forme_un "$w")"); done
  for v in 'Fiab' 'fia/x' 'fia_bis' '../fia' fiabilite ws-2; do w="\"ws\":\"$v\""; a+=("$(rgm_forme_un "$w")"); done
  for v in 73 73.1 7x '../73' '73.' '.5'; do w="\"phase\":\"$v\""; a+=("$(rgm_forme_un "$w")"); done
  for v in depot mission compartiment /etc autre; do w="\"scope\":\"$v\""; a+=("$(rgm_forme_un "$w")"); done
  for v in dag-73.json '../dag.json' '/abs/dag.json' '..' 'a/b.json'; do w="\"dag\":\"$v\""; a+=("$(rgm_forme_un "$w")"); done
  unset IFS; rgm_json "${a[@]}" > "$1"
}
rgm_forme_cas() {
  local sc="$WORK/s63.json" o="$WORK/o63.json" L
  rgm_forme_sc "$sc"; rgm_play "$UI" "$sc" "$o"
  assert_eq "RG6.3 — owner et étape : chemin au milieu, relatif, file:, ../, ~, espace, « .. » refusés ; valeurs réelles gardées" \
    "$(g "$o" 'j.slice(0,11).map(x=>x.owner===x.step?x.owner:"!").join(",")')" ",,,,,,,release-bump,exec-73,vf-dev-manager-p73,3f9a0c1e7b"
  assert_eq "RG6.3 — ws : minuscules, chiffres, tiret" "$(g "$o" 'j.slice(11,17).map(x=>x.ws).join(",")')" ",,,,fiabilite,ws-2"
  assert_eq "RG6.3 — phase : entier, décimale éventuelle" "$(g "$o" 'j.slice(17,23).map(x=>x.phase).join(",")')" "73,73.1,,,,"
  assert_eq "RG6.3 — scope : liste fermée" "$(g "$o" 'j.slice(23,28).map(x=>x.scope).join(",")')" "depot,mission,compartiment,,"
  assert_eq "RG6.3 — dag : forme de nom de fichier, aucune séparation" "$(g "$o" 'j.slice(28,33).map(x=>x.dag===undefined?"-":x.dag).join(",")')" "dag-73.json,-,-,-,-"
  L="$(rgm_lock 'a/Users/quidam/lab' depot '' 840 false null)"
  rgm_json "$(rgm_modele "$(rgm_sess)" "$L")" > "$WORK/s64.json"; rgm_play "$UI" "$WORK/s64.json" "$WORK/o64.json"
  assert_eq "RG6.3 — owner refusé : « détenteur inconnu », la valeur ne s'affiche pas" "$(g "$WORK/o64.json" 'j[0].entete.verrouDepot.texte')" "Verrou du dépôt : détenteur inconnu · exec · tenu depuis 14 min · dernier signe il y a 3 min"
}
rgm_sonde_forme() { rgm_forme_sc "$WORK/s63m.json"; rgm_play "$1" "$WORK/s63m.json" "$WORK/o63.mut"; g "$WORK/o63.mut" 'j.map(x=>[x.owner,x.step,x.ws,x.phase,x.scope,x.dag].join("~")).join("#")'; }
rgm_sonde_verrou() { rgm_play "$1" "$WORK/s61.json" "$WORK/o61.mut"; g "$WORK/o61.mut" '/SENT|quidam|session_ids/.test(JSON.stringify(j[0]))+"|"+j[1].owner.length+"|"+JSON.stringify(j[2].owner)+"|"+j[3].owner'; }

rg_RG7_modele() {
  local sc="$WORK/sc7.json" o="$WORK/o7.json"
  local A="{\"seq\":1,\"at\":\"t\",\"verrous\":{\"etat\":\"lue\",\"plat\":false,\"liste\":[{\"ws\":\"aaa\",\"scope\":\"mission\",\"phase\":\"1\",\"step\":\"s\",\"tenu\":true,\"stale\":false,\"ageS\":5,\"ttl\":1800,\"progressAgeS\":null,\"owner\":\"o\",\"leaseS\":5},"
  local Z1='{"ws":"zzz","scope":"mission","phase":"73","step":"s","tenu":true,"stale":true,"ageS":5,"ttl":1800,"progressAgeS":1620,"owner":"o","leaseS":5}]}}'
  local Z0='{"ws":"zzz","scope":"mission","phase":"73","step":"s","tenu":true,"stale":false,"ageS":5,"ttl":1800,"progressAgeS":null,"owner":"o","leaseS":5}]}}'
  rgm_json "$(rgm_modele "$(rgm_sess)" "$A$Z1")" "$(rgm_modele "$(rgm_sess)" "$A$Z1" "$RGM_CXN")" "$(rgm_modele "$(rgm_sess)" "$A$Z0")" \
    "$(rgm_appel etatVivant '[{"kind":"subagent","etat":"actif","ageS":1080},{"now":1000000000000,"recuA":1000000000000,"fenetre":null}]')" > "$sc"
  rgm_play "$UI" "$sc" "$o"
  local mq='.sections[1].lignes.filter(l=>l.kind==="mission").map(l=>(l.marques||[]).map(x=>x.texte).join("+")).join("|")'
  assert_eq "RG7.6 — stale : « verrou abandonné » ; progressAgeS 1 620 sur fenêtre 900 : « aucun nœud marqué depuis 27 min »" "$(g "$o" "j[0]$mq")" "|verrou abandonné+aucun nœud marqué depuis 27 min"
  assert_eq "RG7.6 — fenêtre inconnue (null) : aucune marque de progrès, jamais d'inférence" "$(g "$o" "j[1]$mq")" "|verrou abandonné"
  local ordre='.sections[1].lignes.filter(l=>l.kind==="mission").map(l=>l.cle).join("|")'
  assert_eq "RG7.6 — les marques ne reclassent rien : même ordre des lignes avec et sans marques" "$(g "$o" "j[0]$ordre===j[2]$ordre")" "true"
  if [ -f "$UI/72-vf-regie-modele.js" ]; then
    rg_mutant "STALL-INCONNU-MARQUE" "fenêtre null traitée comme 900" "$UI" "72-vf-regie-modele.js" 'return nbf(v) ? v : null; };' 'return nbf(v) ? v : 900; };' rgm_sonde_stall "|verrou abandonné#silencieux depuis 18 min"
  else assert_eq "M-STALL-INCONNU-MARQUE — modèle présent pour muter" "absent" "présent"; fi
}
rgm_sonde_stall() { rgm_play "$1" "$WORK/sc7.json" "$WORK/o7.mut"; g "$WORK/o7.mut" 'j[1].sections[1].lignes.filter(l=>l.kind==="mission").map(l=>(l.marques||[]).map(x=>x.texte).join("+")).join("|")+"#"+j[3].mot'; }

rg_RG8_modele() {
  local sc="$WORK/sc8.json" o="$WORK/o8.json" w cx
  w='{"workers":[{"kind":"session","id":"s-l","etat":"actif","titre":"Lancée","tree":".claude/worktrees/phase-72-a","branch":"feat/alpha","ageS":10,
 "rattachement":{"etat":"rattache","dag":"plan-72","noeud":"plan-72-03"},"lancee":{"phase":"72","ws":"alpha","verbe":"executer"}}]}'
  cx='{"now":1000000000000,"recuA":1000000000000,"fenetre":900,"lus":null,"nonCommite":{"feat/alpha":3},"missions":[]}'
  rgm_json "$(rgm_modele "$w" null "$cx")" "$(rgm_modele "$w")" > "$sc"
  rgm_play "$UI" "$sc" "$o"
  assert_eq "RG8.0 — ligne 2 d'une session : nœud, modifiés, arbre, branche, lancement" "$(g "$o" 'j[0].sections[1].lignes[0].ligne2.join(" | ")')" "nœud plan-72-03 | 3 modifiés | arbre phase-72-a | branche feat/alpha | Lancée depuis la carte : Phase 72 · alpha · exécuter"
  assert_eq "RG8.0 — sans jointure de branche, aucun « modifiés »" "$(g "$o" 'j[1].sections[1].lignes[0].ligne2.some(p=>/modifié/.test(p))')" "false"
}

rg_RG9_modele() {
  local sc="$WORK/sc9.json" o="$WORK/o9.json" cx='{"now":1000000000000,"recuA":1000000000000,"fenetre":900}' cxp='{"now":1000000000000,"recuA":1000000000000,"fenetre":600}' ev
  local cmd='"enCours":true,"action":{"verbe":"lance une commande","cible":"x"}'
  ev() { rgm_appel etatVivant "[{\"kind\":\"subagent\",\"etat\":\"actif\",$1},$2]"; }
  local WO='{"workers":[
 {"kind":"session","id":"p","etat":"termine","titre":"Parti","tree":".","ageS":4000,"dureeS":9},
 {"kind":"subagent","id":"o","etat":"actif","orphan":true,"parent":"p","role":"vf-coder","task":"Orphelin","ageS":100,"dureeS":700,"tree":"."}]}'
  rgm_json "$(ev '"ageS":60' "$cx")" "$(ev '"ageS":240' "$cx")" "$(ev '"ageS":1080' "$cx")" "$(ev "\"ageS\":420,$cmd" "$cx")" "$(ev "\"ageS\":1320,$cmd" "$cx")" \
    "$(ev "\"ageS\":720,$cmd" "$cxp")" "$(ev "\"ageS\":1320,$cmd" "$cxp")" "$(ev '"ageS":1080' '{"now":1000000000000,"recuA":1000000000000,"fenetre":null}')" \
    "$(rgm_modele "$WO")" \
    "$(rgm_appel etatVivant '[{"kind":"subagent","etat":"actif","ageS":60},{"now":1000000000000,"recuA":1000000000000,"fenetre":900}]')" \
    "$(rgm_appel etatVivant '[{"kind":"subagent","etat":"actif","ageS":60},{"now":1000000200000,"recuA":1000000000000,"fenetre":900}]')" \
    "$(rgm_modele "$RGM_W5")" "$(rgm_appel _rendu '[]')" > "$sc"
  rgm_play "$UI" "$sc" "$o"
  assert_eq "RG9.1 — actif écrit il y a 60 s : « au travail »" "$(g "$o" 'j[0].mot+"|"+j[0].etat')" "au travail|actif"
  assert_eq "RG9.1 — 240 s : « silencieux depuis 4 min »" "$(g "$o" 'j[1].mot+"|"+j[1].etat')" "silencieux depuis 4 min|surveiller"
  assert_eq "RG9.1 — 1 080 s, fenêtre 900 : « suspect », poids 600" "$(g "$o" 'j[2].mot+"|"+j[2].poids')" "suspect : aucun signe de vie depuis 18 min|600"
  assert_eq "RG9.2 — outil en cours depuis 7 min : « commande en cours depuis 7 min », toujours au travail" "$(g "$o" 'j[3].detail+"|"+j[3].mot')" "commande en cours depuis 7 min|au travail"
  assert_eq "RG9.2 — 22 min : « commande longue : 22 min »" "$(g "$o" 'j[4].mot+"|"+j[4].poids')" "commande longue : 22 min|600"
  assert_eq "RG9.2 — fenêtre 600 : 12 min restent « commande en cours » (le seuil de commande longue n'est pas la fenêtre) ; 22 min restent « longue »" "$(g "$o" 'j[5].detail+"|"+j[6].mot')" "commande en cours depuis 12 min|commande longue : 22 min"
  assert_eq "RG9.3 — fenêtre inconnue : jamais « suspect », la décroissance s'arrête à « silencieux »" "$(g "$o" 'j[7].mot')" "silencieux depuis 18 min"
  assert_eq "RG9.4 — orphelin sous la ligne grisée de son parent terminé : mot, niveau, aucune action" "$(g "$o" '(()=>{const L=j[8].sections[1].lignes.filter(l=>l.kind!=="mission"); return L.map(l=>[l.id,l.grise,l.mot,l.niveau,l.parent,l.action].map(String).join(":")).join("|")})()')" "p:true:terminé:0:null:null|o:false:orphelin:1:p:null"
  assert_eq "RG9.6 — l'âge avance avec le temps écoulé depuis la réception : 60 s reçus il y a 200 s" "$(g "$o" 'j[10].mot')" "silencieux depuis 4 min"
  assert_eq "RG9.6 — contre-épreuve : 60 s reçus à l'instant restent « au travail »" "$(g "$o" 'j[9].mot')" "au travail"
  assert_eq "RG9.7 — chaque attrs.etat est une valeur de GLYPHE_ETAT ou surveiller, orphelin, attente" "$(g "$o" '(()=>{const ok=new Set([...j[12].glyphes,"surveiller","orphelin","attente"]); const l=[...j[8].sections,...j[11].sections].flatMap(s=>s.lignes.concat(s.relus||[])).filter(x=>x.kind!=="mission"); return (l.length>0 && l.every(x=>ok.has(x.attrs.etat)))})()')" "true"
  assert_eq "RG9.7 — le modèle ne porte aucune forme de glyphe et pose les six exports du modèle" "$(g "$o" 'j[12].glypheCopie+"|"+j[12].sansDocument+"|"+j[12].modele.slice().sort().join(",")')" "false|true|aVous,etatVivant,modele,trierAVous,verrouBlanc,verrous"
  local d="$WORK/o9b.json"; rgm_play "$UI" "$WORK/sc9.json" "$d" brut
  assert_eq "RG9.8 — espaces insécables avant « : » et entre nombre et unité" "$(g "$d" 'j[2].mot===`suspect : aucun signe de vie depuis 18 min`')" "true"
  if [ -f "$UI/72-vf-regie-modele.js" ]; then
    rg_mutant "CALME" "seuil de silence lu à 300" "$UI" "72-vf-regie-modele.js" '!cmd && age != null && age >= r.CALME_S' '!cmd && age != null && age >= 300' rgm_sonde_calme "silencieux depuis 4 min"
    rg_mutant "LONGUE-EGALE-STALL" "seuil de commande longue lu dans la fenêtre" "$UI" "72-vf-regie-modele.js" 'age >= r.LONGUE_S' 'age >= (fen == null ? r.LONGUE_S : fen)' rgm_sonde_longue "commande en cours depuis 12 min"
    rg_mutant "ORPHELIN-ACTION" "l'orphelin reçoit l'action lire-rapport" "$UI" "72-vf-regie-modele.js" "action: lire ? 'lire-rapport' : null," "action: lire || e.etat === 'orphelin' ? 'lire-rapport' : null," rgm_sonde_orphelin "null"
    rg_mutant "GLYPHE-COPIE" "table de glyphes locale à la place de celle de 71" "$UI" "72-vf-regie-modele.js" 'G = r.GLYPHE_ETAT' "G = { actif: 'a', 'en-attente': 'b', 'au-repos': 'c', attend: 'd', termine: 'e', bloque: 'f' }" rgm_sonde_glyphes "true"
  else assert_eq "M-CALME, M-LONGUE-EGALE-STALL, M-ORPHELIN-ACTION, M-GLYPHE-COPIE — modèle présent pour muter" "absent" "présent"; fi
}
rgm_sonde_calme() { rgm_play "$1" "$WORK/sc9.json" "$WORK/o9.mut"; g "$WORK/o9.mut" 'j[1].mot'; }
rgm_sonde_longue() { rgm_play "$1" "$WORK/sc9.json" "$WORK/o9.mut"; g "$WORK/o9.mut" 'j[5].detail'; }
rgm_sonde_orphelin() { rgm_play "$1" "$WORK/sc9.json" "$WORK/o9.mut"; g "$WORK/o9.mut" 'j[8].sections[1].lignes.find(l=>l.id==="o").action'; }
rgm_sonde_glyphes() { rgm_play "$1" "$WORK/sc9.json" "$WORK/o9.mut"; g "$WORK/o9.mut" '(()=>{const ok=new Set([...j[12].glyphes,"surveiller","orphelin","attente"]); const l=[...j[8].sections,...j[11].sections].flatMap(s=>s.lignes.concat(s.relus||[])).filter(x=>x.kind!=="mission"); return (l.length>0 && l.every(x=>ok.has(x.attrs.etat)))})()'; }

rg_RG10_modele() {
  local sc="$WORK/sc10.json" o="$WORK/o10.json" cx='{"now":1000000000000,"recuA":1000000000000,"fenetre":900}'
  rgm_json "$(rgm_ev session en-attente '"attendAgents":3,"ageS":400' "$cx")" "$(rgm_ev subagent en-attente '"attendAgents":3,"ageS":400' "$cx")" \
    "$(rgm_ev session actif '"attendAgents":3,"ageS":30' "$cx")" > "$sc"
  rgm_play "$UI" "$sc" "$o"
  assert_eq "RG10.6 — session non active avec attendAgents 3 : « attend ses agents (3) »" "$(g "$o" 'j[0].mot+"|"+j[0].etat')" "attend ses agents (3)|attente"
  assert_eq "RG10.6 — sous-agent : champ ignoré ; session active : champ ignoré" "$(g "$o" 'j[1].mot+"|"+j[2].mot')" "en attente|au travail"
}

rg_RG11_modele() {
  local sc="$WORK/sc11.json" o="$WORK/o11.json" w i="" cx='{"now":1000000000000,"recuA":1000000000000,"fenetre":900}'
  w='{"workers":[{"kind":"session","id":"s-close","etat":"termine","titre":"Close","tree":".","ageS":500}'
  for i in 1 2 3 4 5 6 7 8 9 10; do w="$w,{\"kind\":\"subagent\",\"id\":\"t$i\",\"etat\":\"termine\",\"role\":\"vf-coder\",\"task\":\"Tâche $i\",\"ageS\":$((60*i)),\"dureeS\":$((100*i)),\"tree\":\".\"}"; done
  w="$w]}"
  local lus='{"now":1000000000000,"recuA":1000000000000,"fenetre":900,"lus":{"t1":1},"nonCommite":{},"missions":[]}'
  rgm_json "$(rgm_modele "$w" null "$lus")" "$(rgm_modele "$w")" \
    "$(rgm_ev subagent termine '"finMotif":"echec","ageS":180,"dureeS":1740' "$cx")" "$(rgm_ev subagent termine '"finMotif":"arret","ageS":180,"dureeS":1740' "$cx")" \
    "$(rgm_ev subagent termine '"ageS":180,"dureeS":1740' "$cx")" > "$sc"
  rgm_play "$UI" "$sc" "$o"
  assert_eq "RG11.1 — hors « lus », du plus récent au plus ancien : huit lignes puis « Un autre » ; compte = 9" "$(g "$o" '(()=>{const s=j[0].sections[2]; return s.compte+"|"+s.lignes.map(l=>l.id).join(",")+"|"+s.autres+"|"+s.autresTexte})()')" "9|t2,t3,t4,t5,t6,t7,t8,t9|1|Un autre"
  assert_eq "RG11.1 — « lus » absent : tout est à relire (repli sans stockage) ; « Les 2 autres »" "$(g "$o" '(()=>{const s=j[1].sections[2]; return s.compte+"|"+s.lignes.length+"|"+s.autresTexte})()')" "10|8|Les 2 autres"
  assert_eq "RG11.1 — l'agent lu et la session close vont dans les relus, sans bouton" "$(g "$o" 'j[0].sections[2].relus.map(l=>l.id+":"+l.action).join(",")')" "t1:null,s-close:null"
  assert_eq "RG11.1 — une ligne à relire : coche, « il y a », « a duré », bouton « lire-rapport »" "$(g "$o" '(()=>{const l=j[0].sections[2].lignes[0]; return [l.etat,l.detail,l.duree.prefixe,l.duree.valeur,l.action,l.cle].join("|")})()')" "termine|il y a 2 min|a duré|3 min|lire-rapport|a-relire:t2"
  assert_eq "RG11.5 — finMotif : « échec », « arrêté », absent : « rapport rendu »" "$(g "$o" 'j[2].mot+"|"+j[3].mot+"|"+j[4].mot')" "échec|arrêté|rapport rendu"
}

rg_RG14_modele() {
  local f="$UI/72-vf-regie-style.js"
  cat > "$AUX/feuille.mjs" <<'JS'
// feuille.mjs <fichier> : « ok » ou la liste des écarts de la feuille de la régie (masquage hors .vf-regie-montee, style de bouton, variable interdite)
import fs from 'node:fs';
let t; try { t = fs.readFileSync(process.argv[2], 'utf8'); } catch { console.log('fichier absent'); process.exit(0); }
const css = [...t.matchAll(/`([^`]*)`/g)].map((x) => x[1]).join('\n'), pb = []; if (/--st-recette/.test(t)) pb.push('--st-recette');
for (const m of css.matchAll(/([^{}]+)\{([^{}]*)\}/g)) {
  const sel = m[1].replace(/\/\*[\s\S]*?\*\//g, '').trim(), corps = m[2];
  if (/#stage|#zoom|#z-fit|#results|#crumbs/.test(sel) && !/vf-regie-montee/.test(sel)) pb.push(`masquage hors .vf-regie-montee : ${sel}`);
  if (/button/.test(sel)) pb.push(`sélecteur de bouton : ${sel}`);
  if (/\.btn\b/.test(sel)) for (const d of corps.split(';')) { const p = d.split(':')[0].trim(); if (p && !/^(height|min-height)$/.test(p)) pb.push(`.btn : ${p} (${sel})`); }
}
console.log(pb.length ? pb.join(' ; ') : 'ok');
JS
  assert_eq "RG14.0 — jetons existants seuls (css-jetons.mjs : couleur, espacement, rayon)" "$(node "$TESTS_DIR/css-jetons.mjs" "$f" > "$WORK/jetons.out" 2>&1; echo $?)" "0"
  assert_eq "RG14.0 — pas de --st-recette, pas de style de bouton hors la hauteur de .btn, masquage seulement sous .vf-regie-montee" "$(node "$AUX/feuille.mjs" "$f")" "ok"
}
