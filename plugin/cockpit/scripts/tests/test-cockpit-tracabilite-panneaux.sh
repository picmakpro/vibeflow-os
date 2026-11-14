#!/usr/bin/env bash
# test-cockpit-tracabilite-panneaux.sh — décisions, ADR, commits et mémoire des agents au cockpit, côté page (76-07)
#   C3.1-C3.9 section « Décisions », panneaux d'ADR et de décision, registres, commits vers le tiroir Git, plafond de 30, borne (chrome-tracabilite-panneaux.mjs)
#   C4.1-C4.10 section « Mémoire des agents », liste d'un agent, panneau d'une entrée, chaînes de Retour, absences, confidentialité (chrome-tracabilite-memoire.mjs)
# Labs fabriqués dans mktemp (aucun chemin du poste dans les fichiers écrits), HOME jetable, isolation git. Sans navigateur : suite SAUTÉE (jamais un vert à vide).
# Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=Alice GIT_AUTHOR_EMAIL=a@t.test GIT_COMMITTER_NAME=Alice GIT_COMMITTER_EMAIL=a@t.test
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then . "$HERE_T/chrome-saut.sh"; vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — décisions et mémoire côté page NON vérifiées, non comptées comme réussies"; exit 0; fi
mkdir -p "${TMPDIR:-/tmp}"; WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || { chmod -R u+rwx "$WORK" 2>/dev/null; rm -rf "$WORK"; }' EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
. "$HERE_T/socle-serveur.sh"
PASS=0; FAIL=0
assert_eq() { if [ "$#" -ne 3 ]; then echo "  ❌ FAIL — $1 (assert_eq : $# arguments au lieu de 3)"; FAIL=$((FAIL+1)); elif [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:600}]"; FAIL=$((FAIL+1)); fi; }
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('sortie illisible'); process.exit(0); }
if (j.erreur) { console.log('mesure indisponible : ' + j.erreur); process.exit(0); }
let v; try { v = new Function('j', 'return (' + process.argv[2] + ')')(j); } catch (e) { console.log('absent : ' + e.message); process.exit(0); }
console.log(v === undefined ? 'absent' : typeof v === 'string' ? v : JSON.stringify(v));
JS
wr() { mkdir -p "$(dirname "$1")"; cat > "$1"; }
# gc <lab> <date> <message> : tout ajouter puis commit daté
gc() { git -C "$1" add -A >/dev/null 2>&1; GIT_AUTHOR_DATE="$2T12:00:00Z" GIT_COMMITTER_DATE="$2T12:00:00Z" git -C "$1" commit -q -m "$3"; }
# mem <lab> <agent> <fichier> <name> <type> [corps] / idx <lab> <agent> <lignes> : entrée de mémoire et index d'un agent
mem() { local f="$1/.claude/agent-memory/$2/$3"; mkdir -p "$(dirname "$f")"; printf -- '---\nname: %s\ndescription: DESC-MARQUEUR-76\nmetadata:\n  type: %s\n---\n\n%s\n' "$4" "$5" "${6:-corps}" > "$f"; }
idx() { mkdir -p "$1/.claude/agent-memory/$2"; printf '# Mémoire\n\n%s\n' "$3" > "$1/.claude/agent-memory/$2/MEMORY.md"; }
mkroad() { # <lab> <n…> : feuille de route et état d'un compartiment x, une phase par numéro, registre des exigences minimal
  local L="$1" B="$1/.planning/workstreams/x" n; shift; mkdir -p "$B"
  { printf '# Roadmap\n\n## Milestones\n\n- 🚧 **v1** - Phases 1-99 (in progress)\n\n## Phases\n\n'
    for n in "$@"; do printf -- '- [ ] **Phase %s: P%s** - p\n' "$n" "$n"; done; printf '\n'
    for n in "$@"; do printf '### Phase %s: P%s\n**Goal**: but %s\n**Depends on**: Nothing\n\n' "$n" "$n" "$n"; done; } > "$B/ROADMAP.md"
  printf -- '---\nmilestone: v1\nstatus: executing\ncurrent_phase: %s\n---\n' "$1" > "$B/STATE.md"; [ -f "$B/REQUIREMENTS.md" ] || printf '# Exigences\n' > "$B/REQUIREMENTS.md"
}
batir() { node "$SCRIPTS/vf-cockpit-build.mjs" "$1" --quiet > "$WORK/build.out" 2>&1 || { echo "assemblage KO"; cat "$WORK/build.out"; }; }
sha7() { git -C "$1" log -1 --format=%H --grep="$2" | cut -c1-7; }
# lab L : ADR-001 (titre à marqueur) et ADR-002 sans commit ; registre de la phase 90 (P90-D-01 cite ADR-001 et ADR-007 sans section, P90-D-02, D-04 nue) ;
# REQ-01 cite P90-D-01 ; mémoire de trois agents (4 entrées : une hors index, un lien cassé, un lien par nom de fichier, un chemin cité absent ; l'agent « vide » n'a qu'un index)
mklabL() {
  local L="$1" B="$1/.planning/workstreams/x"; mkroad "$L" 90
  wr "$B/REQUIREMENTS.md" <<'MD'
# Exigences

- [ ] **REQ-01**: Exigence de la phase quatre-vingt-dix (P90-D-01)

| REQ-01 | Phase 90 | Pending |
MD
  wr "$B/phases/90-registre/90-CONTEXT.md" <<'MD'
# Contexte

- **P90-D-01** : DECISION-MARQUEUR-76 première définition (ADR-001, ADR-007)
- **P90-D-02** : deuxième définition
- **D-04** : décision nue, ambiguë
MD
  wr "$L/docs/ADR.md" <<'MD'
# ADR

## ADR-001 — Premier choix ADR-MARQUEUR-76

texte

## ADR-002 — Second choix

texte
MD
  printf 'v\n' > "$L/docs/vieux.md"; printf '.vibeflow/\n' > "$L/.gitignore"; git -C "$L" init -q -b main; gc "$L" 2026-11-01 init
  git -C "$L" rm -q docs/vieux.md; gc "$L" 2026-11-02 'retrait de docs/vieux.md'
  idx "$L" vf-coder '- [A](a.md) [B](b.md)'; idx "$L" vf-reviewer '- [X](x.md)'; idx "$L" vide '- aucune entrée'
  mem "$L" vf-coder a.md entree-a-MEMOIRE-MARQUEUR-76 project 'liens [[c]] [[inconnu]] [[revue-1]]
CORPS-MARQUEUR-76'
  mem "$L" vf-coder b.md entree-b feedback 'cite docs/vieux.md
CORPS-MARQUEUR-76'
  mem "$L" vf-coder c.md autre-nom-c project 'rien'; mem "$L" vf-reviewer x.md revue-1 project 'rien'
  gc "$L" 2026-11-08 'mémoire des agents'
  printf 'a\n' > "$L/src.txt"; gc "$L" 2026-11-09 'feat: suit ADR-001'
  printf 'b\n' > "$L/src.txt"; gc "$L" 2026-11-10 'docs: note sur D-04'
  printf 'c\n' > "$L/src.txt"; gc "$L" 2026-11-11 'fix: applique P90-D-01'
  batir "$L"
}
# lab R : 31 registres de phase (phases 50 à 80, la 80 en porte deux), aucun docs/ADR.md
mklabR() {
  local L="$1" B="$1/.planning/workstreams/x" n; mkroad "$L" $(seq 50 80)
  for n in $(seq 50 80); do mkdir -p "$B/phases/$n-p$n"; printf '# Contexte\n\n- **P%s-D-01** : décision de la phase %s, début de définition\n' "$n" "$n" > "$B/phases/$n-p$n/$n-CONTEXT.md"; done
  printf -- '- **P80-D-02** : seconde décision de la phase quatre-vingts\n' >> "$B/phases/80-p80/80-CONTEXT.md"
  printf '.vibeflow/\n' > "$L/.gitignore"; git -C "$L" init -q -b main; gc "$L" 2026-11-01 init; batir "$L"
}
# lab C : ADR-001 et ADR-002, 31 commits qui citent ADR-001, aucun registre de phase
mklabC() {
  local L="$1" n; mkroad "$L" 1; wr "$L/docs/ADR.md" <<'MD'
# ADR

## ADR-001 — Premier choix

texte

## ADR-002 — Second choix

texte
MD
  printf '.vibeflow/\n' > "$L/.gitignore"; git -C "$L" init -q -b main; gc "$L" 2026-11-01 init
  for n in $(seq 1 31); do printf '%s\n' "$n" > "$L/src.txt"; gc "$L" 2026-11-05 "feat: étape $n, suit ADR-001"; done
  batir "$L"
}
# lab I : .claude/ ignoré par git, trois fichiers de mémoire non suivis ; lab G : sans git (ADR et mémoire présentes)
mklabI() { local L="$1" n; mkroad "$L" 1; for n in secret-a secret-b secret-c; do mem "$L" vf-coder "$n.md" "$n" project; done
  printf '.vibeflow/\n.claude/\n' > "$L/.gitignore"; git -C "$L" init -q -b main; gc "$L" 2026-11-01 init; batir "$L"; }
mklabG() { local L="$1"; mkroad "$L" 1; printf '# ADR\n\n## ADR-001 — Premier choix\n\ntexte\n' > "$L/docs.tmp"; mkdir -p "$L/docs"; mv "$L/docs.tmp" "$L/docs/ADR.md"
  idx "$L" vf-coder '- [A](a.md)'; mem "$L" vf-coder a.md entree-g project; rm -rf "$L/.git"; batir "$L"; }
lancer_page() { cockpit_lancer "$@"; }
pret() { cockpit_get '/api/vf/tracabilite?vue=jalon' > "$WORK/j.json"; [ "$VF_CODE" = 200 ] && ! grep -q '"collecte"' "$WORK/j.json"; }
COCKPIT_MODULE="$(cockpit_module_copie "$WORK/module")" && export COCKPIT_MODULE
# harnais <script> <sorties> <sections> : un lab, un serveur déjà lancé ; le JSON de la mesure est gardé dans $WORK/<sortie>.json
harnais() { node "$HERE_T/$1" "$CHROME" "http://127.0.0.1:$VF_PORT" "${3:-}" > "$WORK/$2.json" 2> "$WORK/$2.err"; [ -n "${SONDE:-}" ] && { cat "$WORK/$2.json"; cat "$WORK/$2.err"; }; return 0; }
E() { node "$AUX/ev.mjs" "$2" < "$WORK/$1.json"; }

LL="$WORK/labL"; mklabL "$LL"; lancer_page "$LL"; attendre 30 pret
assert_eq "C0 — témoin : le serveur du lab écoute et la première collecte est faite (ADR, décisions et mémoire servies)" "$([ "${VF_PORT:-0}" -gt 0 ] && cockpit_get '/api/vf/tracabilite?vue=adr' | grep -q '"ADR-001"' && echo oui || echo non)" "oui"
harnais chrome-tracabilite-panneaux.mjs hl "d1,d3,d7,j1,j3"; harnais chrome-tracabilite-memoire.mjs hm "m1,m2,m3,m4,m6,m7,m8,m10"
echo "=== C3.1 à C3.2 — Décisions, ADR, commits qui la citent (tracer) ==="
assert_eq "C3.1a — section « Décisions » repliée par défaut, aucune requête vue=adr avant l'ouverture, une seule à l'ouverture" "$(E hl 'j.d1avant.ferme+"|"+j.d1avant.req+"|"+j.d1sec.req')" "true|0|1"
assert_eq "C3.1b — bilan « 2 ADR · 3 décisions · 1 registre de phase », compteur « 2 ADR », une ligne par ADR avec section (ADR-007 sans section n'en a pas)" "$(E hl 'j.d1sec.bilan+"|"+j.d1sec.compteur+"|"+j.d1sec.ids')" "2 ADR · 3 décisions · 1 registre de phase|2 ADR|ADR-001,ADR-002"
assert_eq "C3.1c — Entrée sur ADR-001 : panneau d'ADR, titre « ADR-001 », id vf-trace-adr-ADR-001, data-trace adr:ADR-001, étiquette « ADR »" "$(E hl 'j.d1adr.titre+"|"+j.d1adr.id+"|"+j.d1adr.trace+"|"+j.d1adr.kind')" "ADR-001|vf-trace-adr-ADR-001|adr:ADR-001|ADR"
assert_eq "C3.1d — le panneau liste « Décisions qui la citent » (P90-D-01) puis « Commits qui la citent », le sha court, le jour en français et le sujet" "$(E hl 'j.d1adr.secs.join()+"|"+j.d1adr.dec+"|"+j.d1adr.commits.join()')" "Décisions qui la citent,Commits qui la citent|P90-D-01|$(sha7 "$LL" 'suit ADR-001')·9 nov. 2026·feat: suit ADR-001"
assert_eq "C3.1e — pied « Lu dans docs/ADR.md », titre lu après le numéro, le corps du message n'apparaît pas" "$(E hl 'j.d1adr.pied+"|"+j.d1adr.pd')" "Lu dans docs/ADR.md|Premier choix ADR-MARQUEUR-76"
assert_eq "C3.2 — témoin voisin : ADR-002 sans commit : « Aucun commit ne cite cet objet. Un message de commit qui nomme son identifiant le relierait. »" "$(E hl 'j.d2.titre+"|"+j.d2.aucun+"|"+j.d2.lignes')" "ADR-002|true|0"
SHA_D="$(sha7 "$LL" 'applique P90-D-01')"
assert_eq "C3.3a — Décisions, « Registres de phase » : un sous-repli « Phase 90, 3 décisions » fermé ; déplié : identifiant et début de définition de P90-D-01, P90-D-02 et D-04" "$(E hl 'j.d3sous.n+"|"+j.d3sous.ferme+"|"+j.d3sous.resume+"|"+j.d3lignes.map(l=>l.split("|")[0]).join()')" "1|true|Phase 90 3 décisions|P90-D-01,P90-D-02,D-04"
assert_eq "C3.3b — panneau de P90-D-01 : étiquette « Décision », titre, titre de définition, sections « Phase », « ADR citées », « Commits qui la citent »" "$(E hl 'j.d3.kind+"|"+j.d3.titre+"|"+j.d3.id+"|"+j.d3.trace+"|"+j.d3.pd+"|"+j.d3.secs.join()')" "Décision|P90-D-01|vf-trace-decision-P90-D-01_ph-90|decision:P90-D-01:ph-90|DECISION-MARQUEUR-76 première définition (ADR-001, ADR-007)|Phase,ADR citées,Commits qui la citent"
assert_eq "C3.3c — « Phase » est un bouton qui sélectionne la phase ; ADR-001 en bouton ; ADR-007 (citée sans section) en texte non interactif « sans section dans docs/ADR.md », non focalisable" "$(E hl '(j.d3.phase.startsWith("Phase 90"))+"|"+j.d3sel+"|"+j.d3.adr.boutons+"|"+JSON.stringify(j.d3.adr.inertes)')" 'true|n:ph-90|ADR-001|[{"tag":"P","texte":"ADR-007 sans section dans docs/ADR.md","tab":null}]'
assert_eq "C3.3d — « Commits qui la citent » : sha, jour et sujet du commit qui nomme P90-D-01 ; pied « Lu dans <registre> »" "$(E hl 'j.d3.commits.join()+"|"+j.d3.pied')" "${SHA_D}·11 nov. 2026·fix: applique P90-D-01|Lu dans .planning/workstreams/x/phases/90-registre/90-CONTEXT.md"
assert_eq "C3.4 — décision nue : titre « D-04, Phase 90 », phrase « Décision nue : … », aucune section ni ligne de commit ; témoin positif : un commit du lab cite « D-04 » et la préfixée porte sa ligne de commit" "$(E hl 'j.d4.titre+"|"+j.d4.nue+"|"+j.d4.lignes+"|"+j.d4.secs.includes("Commits qui la citent")+"|"+j.d3.lignes')|$(git -C "$LL" log --format=%s | grep -c 'D-04')" "D-04, Phase 90|true|0|false|1|1"
assert_eq "C3.7a — clic sur une ligne de commit : VFGitTiroir.ouvrir appelé une fois (espion) ; nom accessible « Commit <sha>, <jour>, <sujet>. Ouvrir dans l'historique Git. »" "$(E hl 'j.d7appels+"|"+j.d7nom')" "1|Commit $(sha7 "$LL" 'suit ADR-001'), 9 nov. 2026, feat: suit ADR-001. Ouvrir dans l'historique Git."
assert_eq "C3.7b — sans VFGitTiroir : la ligne de commit est du texte, aucun button.vf-trace-commit, non focalisable ; témoin positif : la ligne est là" "$(E hl 'j.d7sans.boutons+"|"+(j.d7sans.lignes>0)+"|"+j.d7sans.tab')" "0|true|"
echo "=== C4.1 à C4.10 — Mémoire des agents ==="
assert_eq "C4.1a — section « Mémoire des agents » repliée par défaut, aucune requête vue=memoire avant l'ouverture, une seule à l'ouverture" "$(E hm 'j.m1avant.ferme+"|"+j.m1avant.req+"|"+j.m1.req')" "true|0|1"
assert_eq "C4.1b — bilan en six emplacements, zéros écrits ; compteur de la section « 4 entrées »" "$(E hm 'j.m1.bilan+"|"+j.m1.compteur')" "4 entrées · 3 agents · 1 entrée hors index · 1 lien cassé · 1 chemin cité absent · 2 entrées sans lien entrant|4 entrées"
assert_eq "C4.1c — le bilan reprend les compteurs de la route, sans recalcul (entrées, agents, hors index, liens cassés, chemins absents, sans lien entrant)" "$(E hm '(c=>[c.entrees,c.agents,c.horsIndex,c.liensCasses,c.cheminsAbsents,c.sansEntrant].join()===j.m1.bilan.replace(/[^0-9]+/g," ").trim().split(" ").join())(j.m1route)')" "true"
assert_eq "C4.1d — une ligne par agent : nom, nombre d'entrées, ligne 2 (octogone, contradictions non nulles), ligne 3 (mentions neutres) ou « aucun écart » ; aucun octogone en ligne 3" "$(E hm 'j.m1.agents.map(a=>[a.nom,a.nb,a.mot,a.l3,a.octo,a.octoL3].join("|")).join("//")')" "vf-coder|3 entrées|1 entrée hors index · 1 lien cassé · 1 chemin cité absent|2 entrées sans lien entrant · 1 lien résolu par nom de fichier|1|0//vf-reviewer|1 entrée||aucun écart|0|0//vide|0 entrée||aucun écart|0|0"
assert_eq "C4.2a — liste « Entrées de vf-coder » : nom mono, type, ligne « modifiée le … », contradictions derrière un octogone puis « sans lien entrant » sans glyphe" "$(E hm 'j.m2titre.titre+"|"+j.m2.map(r=>[r.nom,r.type,r.l2,r.l3,r.octo,r.contra].join("|")).join("//")')" "Entrées de vf-coder|entree-a-MEMOIRE-MARQUEUR-76|project|modifiée le 8 nov. 2026 · 0 lien entrant · 3 liens sortants|1 lien cassé · sans lien entrant|1|1 lien cassé//entree-b|feedback|modifiée le 8 nov. 2026 · 0 lien entrant · 0 lien sortant|1 chemin cité absent · sans lien entrant|1|1 chemin cité absent//autre-nom-c|project|modifiée le 8 nov. 2026 · 1 lien entrant · 0 lien sortant|hors index|1|hors index"
assert_eq "C4.2b — agent sans entrée : « Aucune entrée suivie pour cet agent. Un fichier de mémoire suivi par git sous son dossier apparaît ici. »" "$(E hm '(j.m2vide.texte||"").includes("Aucune entrée suivie pour cet agent. Un fichier de mémoire suivi par git sous son dossier apparaît ici.")+"|"+j.m2vide.titre')" "true|Entrées de vide"
assert_eq "C4.3a — entrée entree-a : titre mono, ancre, rappel, fiche, état « sans lien entrant » sans octogone (le lien cassé n'est pas répété), pied « Lu dans … »" "$(E hm 'j.m3a.kind+"|"+j.m3a.titre+"|"+j.m3a.id+"|"+j.m3a.trace+"|"+j.m3a.rappel+"|"+j.m3a.fiche.join()+"|"+j.m3a.secs.join()+"|"+j.m3a.etat.mots.join()+"|"+j.m3a.pied')" "Mémoire|entree-a-MEMOIRE-MARQUEUR-76|vf-trace-entree-vf-coder_a_md|entree:vf-coder/a.md|Seule la structure est lue : ni description ni contenu.|Agent=vf-coder,Type=project,Dernier commit=8 nov. 2026,Liens sortants=3 liens,Liens entrants=0 lien|Fiche,État,Liens sortants|sans lien entrant|Lu dans .claude/agent-memory/vf-coder/a.md"
assert_eq "C4.3b — liens sortants : résolu par nom de fichier (bouton, carré à deux barres), lien cassé (texte non interactif, octogone), résolu (bouton)" "$(E hm 'j.m3a.sortants.join("//")')" "BUTTON|c|résolu par nom de fichier|resolu//DIV|inconnu|lien cassé|contradiction//BUTTON|revue-1|résolu|"
assert_eq "C4.3c — entrée hors index : état « hors index » avec octogone ; liens entrants en boutons, sans lien d'index" "$(E hm 'j.m3c.etat.mots.join()+"|"+j.m3c.secs.join()+"|"+j.m3c.entrants.join()')" "hors index+octogone|Fiche,État,Liens entrants|BUTTON|vf-coder/a.md"
assert_eq "C4.3d — chemin cité absent : ligne non interactive avec octogone, « absent de HEAD, présent dans l'historique lu »" "$(E hm 'j.m3b.absents.join()+"|"+j.m3b.secs.join()+"|"+j.m3b.etat.mots.join()')" "DIV|docs/vieux.md absent de HEAD, présent dans l'historique lu|1|Fiche,État,Chemins cités et absents de HEAD|sans lien entrant"
assert_eq "C4.3e — entrée saine : « Dans l'index, avec au moins un lien entrant. »" "$(E hm 'j.m3x.etat.phrase+"|"+j.m3x.etat.mots.length+"|"+j.m3x.titre+"|"+j.m3x.fiche[4]')" "Dans l'index, avec au moins un lien entrant.|0|revue-1|Liens entrants=1 lien"
assert_eq "C4.4 — ni description ni corps ni « périmée » dans le DOM ni dans les réponses (page posée) ; témoin positif : les marqueurs sont dans les fichiers du lab" "$(E hm 'JSON.stringify(j.m4.dom)+"|"+j.m4.reseau+"|"+j.m4.posee')|$(grep -c 'DESC-MARQUEUR-76\|CORPS-MARQUEUR-76' "$LL/.claude/agent-memory/vf-coder/a.md")" "[]|null|true|2"
assert_eq "C4.6a — Jalon, phase 90, REQ-01 : le Retour nomme la phase ; Retour : la phase, pile vide (bouton désactivé)" "$(E hm 'j.m6a1.label.endsWith(j.m6nom)+"|"+j.m6a2.sel+"|"+j.m6a2.sec+"|"+j.m6a2.back.dis')" "true|n:ph-90|true|true"
assert_eq "C4.6b — Décisions, ADR-001, P90-D-01, phase 90 : le Retour nomme P90-D-01, puis ADR-001, puis la vue d'ensemble, sans doublon ; pile vide ensuite" "$(E hm 'j.m6b0.label.endsWith("P90-D-01")+"|"+j.m6b1.titre+"|"+j.m6b1.back.label.endsWith("ADR-001")+"|"+j.m6b2.titre+"|"+(j.m6b2.back.dis!=="true")+"|"+j.m6b3.pan+"|"+j.m6b3.vue+"|"+j.m6b3.back.dis')" "true|P90-D-01|true|ADR-001|true|false|true|true"
assert_eq "C4.6c — entrée, puis entrée cible par un lien résolu : le Retour nomme l'entrée quittée ; Échap rappelle le Retour commun (l'entrée, le Retour nomme la liste)" "$(E hm 'j.m6c1.label.endsWith("entree-a-MEMOIRE-MARQUEUR-76")+"|"+j.m6c2.titre+"|"+j.m6c2.back.label.endsWith("Entrées de vf-coder")')" "true|entree-a-MEMOIRE-MARQUEUR-76|true"
assert_eq "C4.6d — exigence, décision citée (P76-D-38) : le Retour nomme REQ-01, puis la phase 90 ; ordre phase 90, REQ-01, décision, aucune vue répétée" "$(E hm 'j.m6d0.titre+"|"+j.m6d0.back.label.endsWith("REQ-01")+"|"+j.m6d1.titre+"|"+j.m6d1.back.label.endsWith(j.m6nom)+"|"+j.m6d2.sel+"|"+j.m6d2.sec')" "P90-D-01|true|REQ-01|true|n:ph-90|true"
assert_eq "C4.7a — témoin positif d'abord : éléments .vf-trace posés et visibles ; aucun canevas ni svg dans .vf-trace" "$(E hm '(j.m7a.posees>0)+"|"+j.m7a.visible+"|"+j.m7a.dedans')" "true|true|0"
assert_eq "C4.7b — ordre des sections Jalon, Décisions, Mémoire après le corps ; une section ouverte reste ouverte après un nouveau rendu du panneau" "$(E hm 'j.m7b.ordre+"|"+j.m7b.fin+"|"+j.m7b.ouverts+"|"+j.m7c.ordre+"|"+j.m7c.ouverts')" "vfTraceJalon,vfTraceDecisions,vfTraceMemoire|true|true,true,true|vfTraceJalon,vfTraceDecisions,vfTraceMemoire|true,true,true"
assert_eq "C4.8a — témoin positif : les marqueurs d'ADR, de décision et de mémoire sont visibles dans les sections et les panneaux" "$(E hm 'j.m8sec.includes("ADR-MARQUEUR-76")+"|"+j.m8adr.includes("ADR-MARQUEUR-76")+"|"+j.m8dec.includes("DECISION-MARQUEUR-76")+"|"+j.m8ent.includes("MEMOIRE-MARQUEUR-76")')" "true|true|true|true"
cockpit_exporter "$LL" "$WORK/export.html" > "$WORK/export.out" 2>&1
EXPN="vide"; [ -s "$WORK/export.html" ] && EXPN="$(grep -c 'ADR-MARQUEUR-76\|DECISION-MARQUEUR-76\|MEMOIRE-MARQUEUR-76' "$WORK/export.html")"
assert_eq "C4.8b — l'export existe et ne porte aucun des trois marqueurs (le code de la 76 y est, inactif sans FLOORPLAN_SERVER) ; témoin positif : ils sont dans les fichiers du lab" "$EXPN|$(grep -rl 'ADR-MARQUEUR-76\|DECISION-MARQUEUR-76\|MEMOIRE-MARQUEUR-76' "$LL/docs" "$LL/.planning" "$LL/.claude" | wc -l | tr -d ' ')" "0|3"
assert_eq "C4.10a — Projet, Code, Projet : ADR-001, P90-D-01, Retour (le Retour nomme ADR-001) ; entrée, entrée cible, Retour : chaque panneau se rouvre et revient comme à la première arrivée" "$(E hm 'j.m10a.label.endsWith("ADR-001")+"|"+j.m10b+"|"+j.m10c')" "true|ADR-001|entree-a-MEMOIRE-MARQUEUR-76"
assert_eq "C4.10b — clés bien formées : l'entrée vf-coder/a.md (vf-coder%2Fa.md), la décision P90-D-01:ph-90 (P90-D-01%3Aph-90) et l'ADR passent la grammaire de lireJson (aucun refus), requêtes vues au réseau" "$(E hm 'j.m10cles.join()+"|"+(j.m10req>=3)')" "ok,ok,ok|true"
assert_eq "C4.x — aucune section n'a échoué par erreur de harnais (mémoire)" "$(E hm 'JSON.stringify(j.erreurs)')" "{}"
echo "=== C3.10 à C3.11 — correctifs du juge de design : débordement des panneaux d'objet, indicateur de pliage ==="
assert_eq "C3.10a — panneaux d'objet (ADR, décision, entrée, exigence, liste) à 1 440, 1 024 et 390 px, titre de 3 lignes et chemin long compris : 30 mesures, aucune ne défile à l'horizontale" "$(E hl 'Object.keys(j.j1).length+"|"+Object.entries(j.j1).filter(([k,v])=>!v||v.sw>v.cw).map(([k,v])=>k+":"+(v&&v.sw+">"+v.cw)).join()')" "30|"
assert_eq "C3.10b — en-tête, titre, sections et pied partagent le même bord gauche (20 px) et le même bord droit dans chaque panneau" "$(E hl 'Object.entries(j.j1).filter(([k,v])=>!v||v.gauches!==1||v.droits!==1).map(([k,v])=>k+":"+(v&&v.gauches+"/"+v.droits)).join()')" ""
assert_eq "C3.10c — aucun élément (pastille de type comprise) ne dépasse le bord droit des sections" "$(E hl 'Object.entries(j.j1).filter(([k,v])=>!v||v.hors>0).map(([k,v])=>k+":"+(v&&v.hors)).join()')" ""
assert_eq "C3.11a — sections repliables (Jalon, Décisions, Mémoire, sous-repli) : indicateur de pliage de 16 px au trait, immobile fermé" "$(E hl '["jalon","decisions","memoire","sous"].map(n=>{const c=n==="sous"?j.j3.sous:j.j3[n].ferme;return [c.content,c.w,c.h,c.img,c.t].join("/")}).join("|")')" "$(printf '%s' '""/16px/16px/linear-gradient/none' ; for _ in 1 2 3; do printf '|%s' '""/16px/16px/linear-gradient/none'; done)"
assert_eq "C3.11b — ouvert : l'indicateur est tourné de 90 degrés (Jalon, Décisions, Mémoire)" "$(E hl '["jalon","decisions","memoire"].map(n=>{const m=(j.j3[n].ouvert.t.match(/-?[\d.e-]+/g)||[]).map(Number);return Math.abs(m[0])<.001&&Math.round(m[1])===1}).join()')" "true,true,true"
assert_eq "C3.11c — couleur de --text-3 dans les deux thèmes, sans couleur ajoutée (le clair diffère du sombre)" "$(E hl 'j.j3.light.ok+"|"+j.j3.dark.ok+"|"+(j.j3.light.couleur!==j.j3.dark.couleur)')" "true|true|true"
assert_eq "C3.x — aucune section n'a échoué par erreur de harnais (lab L)" "$(E hl 'JSON.stringify(j.erreurs)')" "{}"
cockpit_arreter
# lab R : 31 registres de phase, pas de docs/ADR.md
LR="$WORK/labR"; mklabR "$LR"; lancer_page "$LR"; attendre 30 pret; harnais chrome-tracabilite-panneaux.mjs hr "d5"
assert_eq "C3.5a — 31 registres : 30 sous-replis fermés, du plus récent (Phase 80, 2 décisions) au plus ancien montré (Phase 51), puis « + 1 autre registre »" "$(E hr 'j.d5.n+"|"+j.d5.ferme+"|"+j.d5.premier+"|"+j.d5.dernier+"|"+j.d5.plus')" "30|true|Phase 80 2 décisions|Phase 51 1 décision|+ 1 autre registre"
assert_eq "C3.5b — un sous-repli ouvert montre ses décisions : identifiant mono et début de la ligne de définition" "$(E hr 'j.d5dec.join("//")')" "P80-D-01|décision de la phase 80, début de définition//P80-D-02|seconde décision de la phase quatre-vingts"
assert_eq "C3.5c — « + 1 autre registre » ouvre la liste « Registres de phase » (« 1 à 30 sur 31 registres ») ; « Suivantes » : le registre de la Phase 50" "$(E hr 'j.d5liste.n+"|"+j.d5liste.compte+"|"+j.d5page2.n+"|"+j.d5page2.resume')" "30|1 à 30 sur 31 registres|1|Phase 50 1 décision"
assert_eq "C3.9a — sans docs/ADR.md : « Pas de docs/ADR.md dans ce dossier. … », les registres de phase restent montrés ; bilan « 0 ADR · 32 décisions · 31 registres de phase »" "$(E hr 'j.d5.sansAdr+"|"+(j.d5.n>0)+"|"+j.d5.bilan')" "true|true|0 ADR · 32 décisions · 31 registres de phase"
assert_eq "C3.x — aucune section n'a échoué par erreur de harnais (lab R)" "$(E hr 'JSON.stringify(j.erreurs)')" "{}"
cockpit_arreter
# lab C : 31 commits qui citent ADR-001, aucun registre
LC="$WORK/labC"; mklabC "$LC"; lancer_page "$LC"; attendre 30 pret; harnais chrome-tracabilite-panneaux.mjs hc "d6"; harnais chrome-tracabilite-memoire.mjs hm5c "m5"
assert_eq "C3.6a — 31 commits citant ADR-001 : 30 lignes puis « + 1 autre commit » ; la liste dit « 1 à 30 sur 31 commits » puis, à « Suivantes », 1 ligne" "$(E hc 'j.d6.n+"|"+j.d6.plus+"|"+j.d6p1.n+"|"+j.d6p1.compte+"|"+j.d6p2.n+"|"+j.d6p2.compte')" "30|+ 1 autre commit|30|1 à 30 sur 31 commits|1|31 à 31 sur 31 commits"
assert_eq "C4.5a — sans .claude/agent-memory/ : « Pas de .claude/agent-memory/ dans ce dossier. Les fichiers de mémoire suivis par git apparaîtraient ici. », aucun bilan" "$(E hm5c 'j.m5.texte+"|"+j.m5.sansBilan')" "Pas de .claude/agent-memory/ dans ce dossier. Les fichiers de mémoire suivis par git apparaîtraient ici.|true"
assert_eq "C3.6b — témoin positif : le lab porte bien 31 commits qui citent ADR-001" "$(git -C "$LC" log --format=%s | grep -c 'ADR-001')" "31"
assert_eq "C3.9b — sans registre : « Aucune décision définie dans les registres de phase. Les lignes Pnn-D-nn d'un fichier CONTEXT de phase apparaissent ici. »" "$(E hc 'j.d6sans')" "true"
assert_eq "C3.x — aucune section n'a échoué par erreur de harnais (lab C)" "$(E hc 'JSON.stringify(j.erreurs)')" "{}"
cockpit_arreter
# même lab C, borne des commits abaissée à 2 (variable d'environnement de la route, voir 76-05)
lancer_page "$LC" VF_COCKPIT_TRACE_MAX_COMMITS=2; attendre 30 pret; harnais chrome-tracabilite-panneaux.mjs hb "d8"
assert_eq "C3.8 — borne atteinte : « Lecture bornée : la liste peut être incomplète. Une lecture plus courte, ou moins de commits, la lèverait. » au-dessus de la liste, 11,5 px, 8 px d'écart, graisse 400" "$(E hb 'j.d8.texte+"|"+j.d8.avant+"|"+j.d8.taille+"|"+j.d8.marge+"|"+j.d8.graisse')" "Lecture bornée : la liste peut être incomplète. Une lecture plus courte, ou moins de commits, la lèverait.|true|11.5px|8px|400"
assert_eq "C3.x — aucune section n'a échoué par erreur de harnais (borne)" "$(E hb 'JSON.stringify(j.erreurs)')" "{}"
cockpit_arreter
LI="$WORK/labI"; mklabI "$LI"; lancer_page "$LI"; attendre 30 pret; harnais chrome-tracabilite-memoire.mjs hm5i "m5"; cockpit_arreter
LG="$WORK/labG"; mklabG "$LG"; lancer_page "$LG"; attendre 30 pret; harnais chrome-tracabilite-memoire.mjs hm5g "m5"; cockpit_arreter
assert_eq "C4.5b — .claude/ ignoré par git : « .claude/ n'est pas suivi par git : 3 fichiers non suivis, aucune entrée à lire. … » ; aucun des trois noms dans le DOM ; témoin positif : ils existent" "$(E hm5i 'j.m5.texte+"|"+j.m5.secret')|$(ls "$LI/.claude/agent-memory/vf-coder" | grep -c secret-)" ".claude/ n'est pas suivi par git : 3 fichiers non suivis, aucune entrée à lire. Suivre .claude/agent-memory/ dans git les rend lisibles.|false|3"
assert_eq "C4.5c — sans git : « Git n'est pas disponible : la mémoire des agents n'est pas lue. Un dépôt git la rend lisible. » et, dans le panneau d'ADR, « Git n'est pas disponible : les commits qui citent cet objet ne sont pas lus. … »" "$(E hm5g 'j.m5.texte+"|"+j.m5adr.includes("Git n"+String.fromCharCode(39)+"est pas disponible : les commits qui citent cet objet ne sont pas lus. Un dépôt git les rend lisibles.")')" "Git n'est pas disponible : la mémoire des agents n'est pas lue. Un dépôt git la rend lisible.|true"
assert_eq "C4.x — aucune section n'a échoué par erreur de harnais (absences)" "$(E hm5c 'JSON.stringify(j.erreurs)')|$(E hm5i 'JSON.stringify(j.erreurs)')|$(E hm5g 'JSON.stringify(j.erreurs)')" "{}|{}|{}"
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
