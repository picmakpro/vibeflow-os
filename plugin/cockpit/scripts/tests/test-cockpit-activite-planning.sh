#!/usr/bin/env bash
# test-cockpit-activite-planning.sh — Phase 75, plan 75-04 (ACTV-10, ACTV-11) : les `files_modified` des plans arrivent, bornés, jusqu'à
# l'instantané de la collecte (`instantane().projet`), avec la `vague` posée par la Phase 80 ; node seul, sans navigateur.
#   T1 le champ survit jusqu'à l'instantané, avec la vague · T2 formes du frontmatter (ligne, bloc, guillemets, CRLF, entrée vide)
#   T3 bornes (200 chemins, 4 096 octets, excédent compté) · T4 un plan sans `files_modified` n'a aucun champ · T5 contrat cockpit-project@1 inchangé
# Fixtures générées dans mktemp (socle commun : projet-commun.sh). Sortie : « PASS — <id> : … », « ❌ FAIL — <id> : … », « BILAN : n PASS, m FAIL » ; sort au premier FAIL.

set -uo pipefail
. "$(dirname "$0")/projet-commun.sh"

NB=0; NF=0
ok() { # ok <id> <texte> <obtenu> <attendu>
  if [ "$3" = "$4" ]; then echo "PASS — $1 : $2"; NB=$((NB+1))
  else echo "❌ FAIL — $1 : $2"; echo "     attendu: [$4]"; echo "     obtenu:  [$3]"; NF=$((NF+1)); echo "BILAN : $NB PASS, $NF FAIL"; exit 1; fi
}

# l'instantané de la collecte : la même étape de planning que le pilote, posée puis relue par instantane() (jamais un autre chemin de lecture)
cat > "$AUX/inst.mjs" <<'JS'
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, root] = process.argv;
const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
const { etapePlanning } = await imp('vf-cockpit-collecte-etapes.mjs');
const { poser, instantane } = await imp('vf-cockpit-instantane.mjs');
poser({ seq: 1, at: 0, git: null, projet: etapePlanning({ racine: root }) });
console.log(JSON.stringify(instantane().projet));
JS
cat > "$AUX/gen.mjs" <<'JS'
// gen.mjs <dossier de phase> : un plan à 5 000 chemins en ligne (05), un plan dont un chemin fait 5 000 octets (06)
import fs from 'node:fs';
const d = process.argv[2];
const tous = Array.from({ length: 5000 }, (_, i) => `src/f${i}.mjs`);
fs.writeFileSync(`${d}/01-05-PLAN.md`, `---\nwave: 1\nfiles_modified: [${tous.join(', ')}]\n---\n<objective>énorme</objective>\n`);
fs.writeFileSync(`${d}/01-06-PLAN.md`, `---\nwave: 1\nfiles_modified: [ok.mjs, ${'x'.repeat(5000)}]\n---\n<objective>géant</objective>\n`);
JS

L="$WORK/lab-planning"; B="$L/.planning"; D="$B/phases/01-socle"
wr "$B/ROADMAP.md" <<'MD'
## Phases

- [ ] **Phase 1: Socle** - non faite
MD
wr "$B/STATE.md" <<'MD'
---
status: executing
current_phase: 1
---
MD
mkdir -p "$D"
printf -- '---\nphase: 1\nplan: 01\nwave: 1\nfiles_modified: [shared.mjs, a.mjs]\n---\n<objective>un</objective>\n' > "$D/01-01-PLAN.md"
printf -- '---\nphase: 1\nplan: 02\nwave: 1\nfiles_modified: ["shared.mjs", b.mjs, "c d.mjs"]\n---\n<objective>deux</objective>\n' > "$D/01-02-PLAN.md"
printf -- '---\nphase: 1\nplan: 03\nwave: 2\n---\n<objective>trois, sans fichiers</objective>\n' > "$D/01-03-PLAN.md"
printf -- '---\nplan: 04\nwave: 2\nfiles_modified:\n  - "bloc/a.mjs"\n  - bloc/b.mjs\n  -\n  - '"'"'bloc/c.mjs'"'"'\nautonomous: true\n---\n<objective>quatre, liste en bloc</objective>\n' > "$D/01-04-PLAN.md"
node "$AUX/gen.mjs" "$D"
printf -- '---\r\nplan: 07\r\nwave: 3\r\nfiles_modified:\r\n  - crlf/a.mjs\r\n  - crlf/b.mjs\r\n---\r\n<objective>sept, CRLF</objective>\r\n' > "$D/01-07-PLAN.md"
printf -- '---\nplan: 08\nwave: 3\nfiles_modified: [e1.mjs, , e2.mjs]\n---\n<objective>huit, entrée vide</objective>\n' > "$D/01-08-PLAN.md"
printf -- '---\nplan: 09\nwave: 0x10\nfiles_modified: []\n---\n<objective>neuf, vide</objective>\n' > "$D/01-09-PLAN.md"

OUT="$WORK/inst.json"
VF_COCKPIT_SCRIPTS_DIR="$WORK/locks" node "$AUX/inst.mjs" "$SCRIPTS" "$L" > "$OUT" 2> "$WORK/inst.err" || { echo "❌ FAIL — T0 : instantané non produit"; cat "$WORK/inst.err"; echo "BILAN : $NB PASS, 1 FAIL"; exit 1; }
plan() { G "$OUT" "(f=>$2)(j.files.find(x=>x.p.endsWith('/phases/01-socle/01-$1-PLAN.md')))"; }

# ---------- T1 — le champ survit jusqu'à l'instantané, avec la vague de la 80 ----------
ok T1 "plan 01 : touched et vague 1 dans instantane().projet" "$(plan 01 'JSON.stringify([f.touched,f.vague])')" '[["shared.mjs","a.mjs"],1]'
ok T1b "plan 02 : touched et vague 1, le fichier partagé y est" "$(plan 02 'JSON.stringify([f.touched,f.vague])')" '[["shared.mjs","b.mjs","c d.mjs"],1]'
ok T1c "plan 09 : vague 0x10 refusée par la 80 (null), la vague n'est pas recalculée ici" "$(plan 09 'String(f.vague)')" 'null'

# ---------- T2 — formes du frontmatter ----------
ok T2 "liste en bloc : guillemets retirés, entrée vide ignorée" "$(plan 04 'JSON.stringify(f.touched)')" '["bloc/a.mjs","bloc/b.mjs","bloc/c.mjs"]'
ok T2b "CRLF : liste en bloc lue comme en LF" "$(plan 07 'JSON.stringify(f.touched)')" '["crlf/a.mjs","crlf/b.mjs"]'
ok T2c "liste en ligne avec entrée vide : ignorée" "$(plan 08 'JSON.stringify(f.touched)')" '["e1.mjs","e2.mjs"]'
ok T2d "liste en ligne entre guillemets (plan 02) : un chemin à espace reste entier" "$(plan 02 'f.touched[2]')" 'c d.mjs'

# ---------- T3 — bornes ----------
ok T3 "5 000 chemins : 200 gardés, 4 800 comptés" "$(plan 05 'f.touched.length+"|"+f.touchedIgnores')" '200|4800'
ok T3b "un chemin de 5 000 octets : ignoré et compté, l'autre gardé" "$(plan 06 'JSON.stringify([f.touched.map(c=>c.length>50?"<long>":c),f.touchedIgnores])')" '[["ok.mjs"],1]'

# ---------- T4 — un plan sans files_modified n'a aucun champ ----------
ok T4 "plan 03 sans files_modified : ni touched ni touchedIgnores" "$(plan 03 '["touched","touchedIgnores"].filter(k=>k in f).length')" '0'
ok T4b "plan 09 (files_modified: []) : ni touched ni touchedIgnores" "$(plan 09 '["touched","touchedIgnores"].filter(k=>k in f).length')" '0'
ok T4c "plan 01 dans les bornes : pas de touchedIgnores" "$(plan 01 '"touchedIgnores" in f')" 'false'

# ---------- T5 — cockpit-project@1 : même version, champs facultatifs non déclarés ----------
ID='vibeflow/cockpit-project@1'
ok T5 "l'instantané porte le schéma $ID et le valide" "$(G "$OUT" 'j.schema')|$(node "$AUX/validate.mjs" "$IFACE" "$ID" "$OUT" | head -1)" "$ID|OK"
ok T5b "touched et touchedIgnores restent facultatifs : absents de requis du bloc" "$(G "$IFACE" "JSON.stringify(['touched','touchedIgnores'].filter(k=>k in (j.schemas['$ID'].requis||{})||(j.schemas['$ID'].element?.requis||[]).includes(k)))")" '[]'

echo "BILAN : $NB PASS, $NF FAIL"
[ "$NF" -eq 0 ] && [ "$NB" -gt 0 ]
