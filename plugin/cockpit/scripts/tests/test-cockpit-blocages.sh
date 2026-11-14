#!/usr/bin/env bash
# test-cockpit-blocages.sh — blocages écrits dans le STATE, servis nettoyés et condensés dans meta.vf.blocagesState (Phase 77, plan 77-02 ; P77-D-10, P77-D-20, SYNT-07 côté données).
# BL0-BL8 : module pur vf-cockpit-blocages.mjs (section « ### Blockers/Concerns » → [{ h, t }]) ; BL9 : lecture du planning (compartiment actif ou lab plat) ;
# BL10 : graphe Projet ; BL11 : contrat déclaré, aucune version montée ; BL12 : STATE réel du compartiment du dépôt.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
. "$(dirname "$0")/projet-commun.sh"

BLM="$SCRIPTS/vf-cockpit-blocages.mjs"
cat > "$AUX/bl.mjs" <<'JS'
// bl.mjs <scripts> <mode> [arg] : exports | lire <fichier> | h <texte> | oracle <texte> | planning <lab>
import fs from 'node:fs';
import crypto from 'node:crypto';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, mode, arg] = process.argv;
const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
let m; try { m = await imp('vf-cockpit-blocages.mjs'); } catch { m = null; }
if (mode === 'oracle') console.log(crypto.createHash('sha256').update(arg.replace(/\*\*|__|`/g, '').replace(/\s+/g, ' ').trim().toLowerCase()).digest('hex').slice(0, 12));
else if (mode === 'exports') console.log(m ? Object.keys(m).sort().join(',') : 'MODULE-ABSENT');
else if (!m) console.log('MODULE-ABSENT');
else if (mode === 'lire') console.log(JSON.stringify(m.lireBlocages(fs.readFileSync(arg, 'utf8'))));
else if (mode === 'h') console.log(m.condensat(arg));
else if (mode === 'planning') { const p = await imp('vf-cockpit-planning.mjs'); console.log(JSON.stringify(p.readPlanning(arg).blocages ?? 'ABSENT')); }
JS
bl() { node "$AUX/bl.mjs" "$SCRIPTS" "$@"; }
lire() { printf '%s\n' "$2" > "$AUX/st-$1.md"; bl lire "$AUX/st-$1.md"; }

# ---------- BL0 ----------
assert_eq "BL0 — exports exacts BORNES, PLACEHOLDERS, condensat, lireBlocages, normaliser" "$(bl exports)" "BORNES,PLACEHOLDERS,condensat,lireBlocages,normaliser"

# ---------- BL1 — puces et continuations ----------
lire 1 $'## Accumulated Context\n\n### Blockers/Concerns\n\n- Premier blocage\n  qui continue\n  sur trois lignes\n* Second blocage\n\n### Quick Tasks Completed\n\n- hors section' > "$WORK/bl1.json"
assert_eq "BL1 — deux puces dont une sur trois lignes (continuation indentée) : deux entrées, texte joint par une espace" "$(G "$WORK/bl1.json" 'JSON.stringify(j.map((e) => e.t))')" '["Premier blocage qui continue sur trois lignes","Second blocage"]'

# ---------- BL2 — section absente / vide ----------
assert_eq "BL2 — section absente : null ; section présente sans puce : []" "$(lire 2a $'### Decisions\n\n- une décision') $(lire 2b $'### Blockers/Concerns\n\nrien à signaler ici\n\n### Suite')" "null []"

# ---------- BL3 — puces de modèle ----------
lire 3 $'### Blockers/Concerns\n\n- None yet.\n- Aucun.\n- **Néant**\n- Un vrai blocage\n\n### Suite' > "$WORK/bl3.json"
assert_eq "BL3 — les puces de modèle (None yet., Aucun., Néant) sont ignorées, le vrai blocage reste" "$(G "$WORK/bl3.json" 'JSON.stringify(j.map((e) => e.t))')" '["Un vrai blocage"]'

# ---------- BL4 — condensat stable ----------
H1="$(bl h '**Phase 23** gelée  derrière ses `arbitrages`')"; H2="$(bl h 'phase 23 gelée derrière ses arbitrages')"; H3="$(bl h 'phase 23 gelée derrière ses arbitrage')"
assert_eq "BL4 — même texte en gras, en minuscules, blancs doublés : même h ; un mot changé : h différent" "$([ -n "$H1" ] && [ "$H1" = "$H2" ] && [ "$H1" != "$H3" ] && echo stable || echo "instable [$H1] [$H2] [$H3]")" "stable"

# ---------- BL5 — oracle du condensat ----------
T5='Le **Texte** `littéral`   du blocage'
assert_eq "BL5 — h = 12 premiers hexadécimaux du SHA-256 du texte normalisé (oracle calculé par node:crypto dans la suite)" "$(bl h "$T5")" "$(bl oracle "$T5")"

# ---------- BL6 — bornes ----------
{ printf '### Blockers/Concerns\n\n'; for i in $(seq 1 30); do printf -- '- blocage numéro %s\n' "$i"; done; printf -- '- '; head -c 2000 /dev/zero | tr '\0' 'x'; printf '\n'; } > "$AUX/st-6.md"
bl lire "$AUX/st-6.md" > "$WORK/bl6.json"
assert_eq "BL6 — 31 puces : 20 entrées au plus" "$(G "$WORK/bl6.json" 'j.length')" "20"
{ printf '### Blockers/Concerns\n\n- '; head -c 2000 /dev/zero | tr '\0' 'x'; printf '\n'; } > "$AUX/st-6b.md"; bl lire "$AUX/st-6b.md" > "$WORK/bl6b.json"
assert_eq "BL6 — une puce de 2 000 caractères : t de 500 au plus (et non vide)" "$(G "$WORK/bl6b.json" '[j.length, j[0].t.length].join("|")')" "1|500"

# ---------- BL7 — nettoyage ----------
printf '### Blockers/Concerns\n\n- a\342\200\256b\007c et https://user:motdepasse@hote/x\n- <img src=x onerror=alert(1)> reste du texte\n' > "$AUX/st-7.md"; bl lire "$AUX/st-7.md" > "$WORK/bl7.json"
assert_eq "BL7 — contrôles et bidi retirés, motif de secret masqué, balise <img onerror> laissée en texte brut (aucune interprétation côté serveur)" "$(G "$WORK/bl7.json" 'JSON.stringify(j.map((e) => e.t))')" '["abc et https://[masqué]@hote/x","<img src=x onerror=alert(1)> reste du texte"]'

# ---------- BL8 — fin de section ----------
lire 8 $'### Blockers/Concerns\n\n- dans la section\n\n### Quick Tasks Completed\n\n- hors section\n\n## Deferred Items\n\n- encore hors' > "$WORK/bl8.json"
assert_eq "BL8 — la section s'arrête au titre suivant (### Quick Tasks Completed) et ne prend pas ses puces" "$(G "$WORK/bl8.json" 'JSON.stringify(j.map((e) => e.t))')" '["dans la section"]'
lire 8b $'### Blockers/Concerns\n\n- dans la section\n\n## Deferred Items\n\n- hors' > "$WORK/bl8b.json"
assert_eq "BL8 — elle s'arrête aussi à un titre de niveau 2" "$(G "$WORK/bl8b.json" 'JSON.stringify(j.map((e) => e.t))')" '["dans la section"]'

# ---------- BL9 — readPlanning : STATE du compartiment actif / lab plat ----------
LP="$WORK/lab-bl-plat"; mkdir -p "$LP/.planning"
printf '## Phases\n\n- [ ] **Phase 1: A** - a\n' > "$LP/.planning/ROADMAP.md"
printf -- '---\nstatus: executing\n---\n\n### Blockers/Concerns\n\n- blocage du lab plat\n' > "$LP/.planning/STATE.md"
LW="$WORK/lab-bl-ws"; mkdir -p "$LW/.planning/workstreams/alpha" "$LW/.planning/workstreams/beta"
for w in alpha beta; do printf '## Phases\n\n- [ ] **Phase 1: A** - a\n' > "$LW/.planning/workstreams/$w/ROADMAP.md"; done
printf -- '---\nstatus: executing\n---\n\n### Blockers/Concerns\n\n- blocage alpha\n' > "$LW/.planning/workstreams/alpha/STATE.md"
printf -- '---\nstatus: executing\n---\n\n### Blockers/Concerns\n\n- blocage beta\n' > "$LW/.planning/workstreams/beta/STATE.md"
printf 'beta\n' > "$LW/.planning/active-workstream"
bl planning "$LP" > "$WORK/bl9a.json"; bl planning "$LW" > "$WORK/bl9b.json"
assert_eq "BL9 — lab plat : blocages vient de .planning/STATE.md ; lab à compartiments : du STATE du compartiment ACTIF (beta, jamais alpha)" "$(G "$WORK/bl9a.json" 'j.map((e) => e.t).join()') / $(G "$WORK/bl9b.json" 'j.map((e) => e.t).join()')" "blocage du lab plat / blocage beta"

# ---------- BL10 — graphe Projet ----------
LB="$WORK/lab-bl-g"; mkdir -p "$LB/.planning"
printf '## Milestones\n\n- 🚧 **v1.0 Démo** - Phases 1-1 (in progress)\n\n## Phases\n\n- [ ] **Phase 1: A** - a\n' > "$LB/.planning/ROADMAP.md"
printf -- '---\nstatus: executing\nmilestone: v1.0 Démo\n---\n\n### Blockers/Concerns\n\n- un blocage écrit dans le STATE\n' > "$LB/.planning/STATE.md"
git -C "$LB" init -q && git -C "$LB" add -A && git -C "$LB" -c user.email=t@t -c user.name=t commit -qm init
graph "$LB" "$WORK/g-bl.json"
bl planning "$LB" > "$WORK/bl10-lect.json"
assert_eq "BL10 — meta.vf.blocagesState égal à la lecture du planning (une entrée, h sur 12 hexadécimaux)" "$(G "$WORK/g-bl.json" 'JSON.stringify(j.meta.vf.blocagesState)') $(G "$WORK/g-bl.json" '/^[0-9a-f]{12}$/.test(j.meta.vf.blocagesState?.[0]?.h)')" "$(cat "$WORK/bl10-lect.json" | tr -d '\n') true"
sed -i.bak '/Blockers/,$d' "$LB/.planning/STATE.md" && rm -f "$LB/.planning/STATE.md.bak"; graph "$LB" "$WORK/g-bl2.json"
assert_eq "BL10 — section absente du STATE : le champ blocagesState est absent du graphe" "$(G "$WORK/g-bl2.json" '"blocagesState" in j.meta.vf')" "false"
assert_eq "BL10 — le graphe valide cockpit-project@1 (validate.mjs)" "$(node "$AUX/validate.mjs" "$IFACE" vibeflow/cockpit-project@1 "$WORK/g-bl.json")" "OK"

# ---------- BL11 — contrat ----------
assert_eq "BL11 — cockpit-project@1 déclare burnup et blocagesState dans optionnels.metaVf (grammaire déjà employée par 76-04) ; la description de cockpit-git@1 nomme base.h ; aucune clé @2 ajoutée" "$(node -e '
const j = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")), p = j.schemas["vibeflow/cockpit-project@1"], g = j.schemas["vibeflow/cockpit-git@1"];
const o = p.optionnels?.metaVf || [];
const nv = Object.keys(j.schemas).filter((k) => /^vibeflow\/cockpit-(project|git)@2$/.test(k)).length;
console.log([o.includes("burnup"), o.includes("blocagesState"), /base\.h/.test(g.description || ""), nv].join("|"));' "$IFACE")" "true|true|true|0"

# ---------- BL12 — STATE réel du compartiment du dépôt ----------
REPO="$(cd "$SCRIPTS/../../.." && pwd)"; STATE_REEL="$REPO/.planning/workstreams/fiabilite/STATE.md"
if [ -f "$STATE_REEL" ]; then bl lire "$STATE_REEL" > "$WORK/bl12.json"; assert_eq "BL12 — le STATE réel du compartiment fiabilite donne au moins une entrée, chaque h sur 12 hexadécimaux" "$(G "$WORK/bl12.json" '(Array.isArray(j) && j.length >= 1 && j.every((e) => /^[0-9a-f]{12}$/.test(e.h))) ? "ok" : "ko"')" "ok"
else echo "  BL12 — non applicable : pas de STATE du compartiment fiabilite dans ce dépôt (ne compte pas comme PASS)"; fi

bilan
