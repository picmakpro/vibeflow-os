#!/usr/bin/env bash
# test-cockpit-tracabilite-memoire.sh — mémoire versionnée des agents lue en structure, fonctions pures sans serveur (TRAC-07, TRAC-08 ; P76-D-19 à P76-D-23)
#   T7 entrée de mémoire : champs servis, périmètre (suivi par git, confiné), mémoire locale et lien sortant exclus, `.claude/` ignoré compté sans noms, bornes
#   T8 liens et états : code et classes POSIX ignorés, résolution en deux temps, hors index exact, sans lien entrant, chemin cité disparu, aucune péremption
# Labs fabriqués dans mktemp (dates de commit fixées, aucun chemin du poste dans les fichiers écrits). Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=Alice GIT_AUTHOR_EMAIL=a@t.test GIT_COMMITTER_NAME=Alice GIT_COMMITTER_EMAIL=a@t.test
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(cd "$SCRIPTS/../../.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"
AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export HOME="$WORK/home"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || { chmod -R u+rwx "$WORK" 2>/dev/null; rm -rf "$WORK"; }' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 — attendu: [$3] obtenu: [$2]"; FAIL=$((FAIL+1)); fi; }

# --- outils node écrits par la suite ---
# j.mjs <fichier> <expression sur j> : JSON lu dans le fichier, expression évaluée ; « absent » si l'expression échoue
cat > "$AUX/j.mjs" <<'JS'
import fs from 'node:fs';
let j; try { j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')); } catch { console.log('illisible'); process.exit(0); }
let v; try { v = new Function('j', 'return (' + process.argv[3] + ')')(j); } catch { console.log('absent'); process.exit(0); }
console.log(v === undefined ? 'absent' : typeof v === 'string' ? v : JSON.stringify(v));
JS
J() { node "$AUX/j.mjs" "$1" "$2" 2>/dev/null || echo "illisible"; }
# memoire.mjs <scripts> <lab> [max] : lecture de la mémoire du lab par les modules de <scripts> ; les passages git d'abord (asynchrones), PUIS toutes les
# lectures de fichiers dans UN appel synchrone lireConfine ; JSON de entreesMemoire plus tronque et nonSuivis
cat > "$AUX/memoire.mjs" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, lab, max] = process.argv;
const imp = (n) => import(pathToFileURL(path.join(scripts, n)).href);
async function sortie() {
  let M, G;
  try { M = await imp('vf-cockpit-trace-memoire.mjs'); G = await imp('vf-cockpit-trace-memoire-git.mjs'); } catch { return { erreur: 'module-absent' }; }
  const { lancerGitAsync, finDans } = await imp('vf-cockpit-paths.mjs');
  const { lireConfine, read, fm } = await imp('vf-cockpit-planning.mjs');
  const racine = fs.realpathSync(lab);
  const fin = finDans(20000);
  const r = await lancerGitAsync(racine, ['rev-parse', '--verify', '--end-of-options', 'HEAD'], { fin, maxBuffer: 1 << 16 });
  const sha = String(r.sortie || '').trim();
  const opt = max ? { fin, max: Number(max) } : { fin };
  const suivis = await G.fichiersSuivis(racine, opt);
  const nonSuivis = await G.nonSuivis(racine, { fin });
  const head = await G.cheminsHead(racine, sha, { fin });
  const supprimes = await G.cheminsSupprimes(racine, sha, { fin });
  const jours = await G.joursMemoire(racine, sha, { fin });
  const index = new Map();
  const fichiers = lireConfine(racine, () => {
    for (const c of suivis.chemins) { const m = /^\.claude\/agent-memory\/([^/]+)\/MEMORY\.md$/.exec(c); if (m) index.set(m[1], read(path.join(racine, c))); }
    return suivis.chemins.map((c) => ({ chemin: c, txt: read(path.join(racine, c)) }));
  });
  const out = M.entreesMemoire({ fichiers, index, head, historique: supprimes.chemins, jours, fm });
  return { ...out, tronque: Boolean(suivis.tronque || supprimes.tronque), nonSuivis };
}
try { console.log(JSON.stringify(await sortie())); } catch (e) { console.log(JSON.stringify({ erreur: 'echec ' + String(e && e.message).slice(0, 120) })); }
JS
# V <lab> [max] -> chemin du fichier JSON produit
V() { local f; f="$WORK/v-$(basename "$1")-${2:-x}.json"; node "$AUX/memoire.mjs" "$SCRIPTS" "$@" > "$f" 2>/dev/null; echo "$f"; }
# E <fichier> <cle> <expression sur l'entrée e> : valeur dans l'entrée de clé <cle>
E() { J "$1" "(e=>e?($3):'sans-entree')(j.entrees.find(x=>x.cle==='$2'))"; }
# SANS <fichier> <marqueur...> : « ok » si la sortie est lisible, non vide et sans aucun des marqueurs ; « fuite » sinon ; « vide » si elle manque
SANS() { local f="$1"; shift; [ -s "$f" ] || { echo vide; return; }; grep -q '"erreur"' "$f" && { echo vide; return; }; local m; for m in "$@"; do grep -qF -- "$m" "$f" && { echo fuite; return; }; done; echo ok; }

# --- fabrication des labs ---
wr() { mkdir -p "$(dirname "$1")"; cat > "$1"; }
# lab_init <dir> : dépôt vide
lab_init() { mkdir -p "$1"; git -C "$1" init -q -b main; git -C "$1" config user.name Alice; git -C "$1" config user.email a@t.test; }
# gc <lab> <date> <message> : tout ajouter puis commit daté
gc() { git -C "$1" add -A >/dev/null 2>&1; GIT_AUTHOR_DATE="$2T12:00:00Z" GIT_COMMITTER_DATE="$2T12:00:00Z" git -C "$1" commit -q -m "$3"; }
# mem <lab> <agent> <fichier> <name | -> <type> [corps] : entrée de mémoire (frontmatter name, description, metadata.type)
mem() { local f="$1/.claude/agent-memory/$2/$3"; mkdir -p "$(dirname "$f")"; { printf -- '---\n'; [ "$4" = "-" ] || printf 'name: %s\n' "$4"; printf 'description: DESC-MARQUEUR-76\nmetadata:\n  type: %s\n---\n\n%s\n' "$5" "${6:-corps}"; } > "$f"; }
# idx <lab> <agent> <lignes> : MEMORY.md de l'agent
idx() { mkdir -p "$1/.claude/agent-memory/$2"; printf '# Mémoire\n\n%s\n' "$3" > "$1/.claude/agent-memory/$2/MEMORY.md"; }

echo "=== T7 — une entrée de mémoire lue en structure seule ==="
L1="$WORK/l1"; lab_init "$L1"
idx "$L1" vf-coder '- [A](a.md) — première'
mem "$L1" vf-coder a.md entree-a project 'voir [[entree-b]]
CORPS-MARQUEUR-76'
mem "$L1" vf-coder b.md entree-b feedback 'rien'
gc "$L1" 2026-01-10 'mémoire'
O1="$(V "$L1")"
assert_eq "T7.1 name lu" "$(E "$O1" vf-coder/a.md 'e.name')" "entree-a"
assert_eq "T7.1 agent = le dossier" "$(E "$O1" vf-coder/a.md 'e.agent')" "vf-coder"
assert_eq "T7.1 metadata.type imbriqué" "$(E "$O1" vf-coder/a.md 'e.type')" "project"
assert_eq "T7.1 jour du dernier commit" "$(E "$O1" vf-coder/a.md 'e.jour')" "2026-01-10"
assert_eq "T7.1 lien résolu par name" "$(E "$O1" vf-coder/a.md 'e.sortants')" '[{"cible":"entree-b","etat":"resolu","vers":"vf-coder/b.md"}]'
assert_eq "T7.1 lien entrant de b" "$(E "$O1" vf-coder/b.md 'e.entrants')" '["vf-coder/a.md"]'
assert_eq "T7.2 témoin positif : description et corps sont dans le fichier du lab" "$(cat "$L1/.claude/agent-memory/vf-coder/a.md" | grep -c 'DESC-MARQUEUR-76\|CORPS-MARQUEUR-76')" "2"
assert_eq "T7.2 ni description ni corps dans la sortie (sortie non vide)" "$(SANS "$O1" DESC-MARQUEUR-76 CORPS-MARQUEUR-76)" "ok"

echo
echo "=== Bilan : $PASS passés, $FAIL échoués ==="
[ "$FAIL" -eq 0 ]
