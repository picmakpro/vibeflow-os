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

echo "T7.9 — chemin du fichier de mémoire, relatif au dépôt"
assert_eq "T7.9 témoin positif : git ls-files du lab liste ce chemin exact" "$(git -C "$L1" ls-files | grep -cx '.claude/agent-memory/vf-coder/a.md')" "1"
assert_eq "T7.9 chemin = chemin relatif au dépôt" "$(E "$O1" vf-coder/a.md 'e.chemin')" ".claude/agent-memory/vf-coder/a.md"
assert_eq "T7.9 aucun chemin absolu ni en ~/" "$(J "$O1" "j.entrees.every(e=>/^\\.claude\\/agent-memory\\/[^/]+\\/[^/]+\\.md\$/.test(e.chemin))")" "true"

echo "T7.3 — mémoire locale exclue"
L2="$WORK/l2"; lab_init "$L2"
idx "$L2" vf-coder '- [A](a.md) — première'
mem "$L2" vf-coder a.md entree-a project 'rien'
mkdir -p "$L2/.claude/agent-memory-local/vf-coder"
printf -- '---\nname: local\nmetadata:\n  type: project\n---\n\nLOCAL-MARQUEUR-76 [[entree-a]]\n' > "$L2/.claude/agent-memory-local/vf-coder/x.md"
gc "$L2" 2026-01-10 'mémoire et locale'
O2="$(V "$L2")"
assert_eq "T7.3 témoin positif : git suit le fichier local" "$(git -C "$L2" ls-files | grep -c 'agent-memory-local/vf-coder/x.md')" "1"
assert_eq "T7.3 aucune entrée sous agent-memory-local" "$(J "$O2" "j.entrees.filter(e=>e.chemin.includes('agent-memory-local')).length")" "0"
assert_eq "T7.3 marqueur local absent de la sortie" "$(SANS "$O2" LOCAL-MARQUEUR-76 agent-memory-local)" "ok"
assert_eq "T7.3 la mémoire locale n'ajoute aucun lien entrant" "$(E "$O2" vf-coder/a.md 'e.entrants')" "[]"

echo "T7.4 — lien symbolique suivi qui sort du lab"
L3="$WORK/l3"; lab_init "$L3"; mkdir -p "$WORK/hors" "$L3/dedans"
printf -- '---\nname: HORS-MARQUEUR-76\nmetadata:\n  type: project\n---\n\n[[HORS-MARQUEUR-76]]\n' > "$WORK/hors/hors.md"
printf -- '---\nname: DANS-LE-LAB-76\nmetadata:\n  type: project\n---\n\ncorps\n' > "$L3/dedans/dans.md"
idx "$L3" vf-coder '- [A](a.md) — première'
mem "$L3" vf-coder a.md entree-a project 'rien'
ln -s "$WORK/hors/hors.md" "$L3/.claude/agent-memory/vf-coder/lien.md"
ln -s "$L3/dedans/dans.md" "$L3/.claude/agent-memory/vf-coder/voisin.md"
gc "$L3" 2026-01-10 'liens symboliques'
O3="$(V "$L3")"
assert_eq "T7.4 témoin positif : le lien rend le marqueur dans le shell" "$(cat "$L3/.claude/agent-memory/vf-coder/lien.md" | grep -c HORS-MARQUEUR-76)" "2"
assert_eq "T7.4 marqueur du fichier hors du lab absent de la sortie entière" "$(SANS "$O3" HORS-MARQUEUR-76)" "ok"
assert_eq "T7.4 l'entrée du lien, si listée, n'a ni name ni lien" "$(E "$O3" vf-coder/lien.md '[e.name,e.sortants.length]')" "[null,0]"
assert_eq "T7.4 témoin positif : un lien vers un fichier du lab est lu" "$(E "$O3" vf-coder/voisin.md 'e.name')" "DANS-LE-LAB-76"

echo "T7.5 — jamais de chemin du poste"
L4="$WORK/l4"; lab_init "$L4"
idx "$L4" vf-coder '- [A](a.md) — première'
mem "$L4" vf-coder a.md entree-a project "lab $L4/docs/z.md, ~/.claude/x.md et $HOME/.claude/y.md"
gc "$L4" 2026-01-10 'chemins du poste'
O4="$(V "$L4")"
assert_eq "T7.5 témoin positif : les trois chemins sont dans le fichier" "$(grep -c -e "$L4/docs/z.md" -e '~/.claude/x.md' -e "$HOME/.claude/y.md" "$L4/.claude/agent-memory/vf-coder/a.md")" "1"
assert_eq "T7.5 aucun des trois dans la sortie" "$(SANS "$O4" "$L4" '~/.claude/x.md' "$HOME" "$WORK")" "ok"

echo "T7.6 — .claude/ ignoré : compté, jamais nommé"
L5="$WORK/l5"; lab_init "$L5"; printf '.claude/\n' > "$L5/.gitignore"; printf 'x\n' > "$L5/readme.txt"
mkdir -p "$L5/.claude/agent-memory/vf-coder"; for n in UN DEUX TROIS; do printf -- '---\nname: n\n---\n' > "$L5/.claude/agent-memory/vf-coder/NONSUIVI-$n.md"; done
gc "$L5" 2026-01-10 'ignoré'
O5="$(V "$L5")"
assert_eq "T7.6 témoin positif : le dossier contient trois noms" "$(ls "$L5/.claude/agent-memory/vf-coder" | grep -c NONSUIVI)" "3"
assert_eq "T7.6 aucun fichier suivi : aucune entrée" "$(J "$O5" "j.entrees.length")" "0"
assert_eq "T7.6 trois fichiers non suivis comptés" "$(J "$O5" "j.nonSuivis.n")" "3"
assert_eq "T7.6 aucun des trois noms dans la sortie" "$(SANS "$O5" NONSUIVI-UN NONSUIVI-DEUX NONSUIVI-TROIS)" "ok"

echo "T7.7 — jour du dernier commit, nombres de liens"
L6="$WORK/l6"; lab_init "$L6"
idx "$L6" vf-coder '- [A](a.md) [B](b.md) [C](c.md)'
mem "$L6" vf-coder a.md entree-a project 'voir [[entree-b]] et [[entree-c]] et encore [[entree-b]]'
mem "$L6" vf-coder b.md entree-b project 'rien'
mem "$L6" vf-coder c.md entree-c project 'rien'
gc "$L6" 2026-01-01 'premier'
mem "$L6" vf-coder a.md entree-a project 'voir [[entree-b]] et [[entree-c]] et encore [[entree-b]] (modifié)'
gc "$L6" 2026-03-05 'second'
O6="$(V "$L6")"
assert_eq "T7.7 entrée modifiée : jour du second commit" "$(E "$O6" vf-coder/a.md 'e.jour')" "2026-03-05"
assert_eq "T7.7 entrée intacte : jour du premier commit" "$(E "$O6" vf-coder/b.md 'e.jour')" "2026-01-01"
assert_eq "T7.7 nombre de liens sortants (une cible citée deux fois compte une fois)" "$(E "$O6" vf-coder/a.md 'e.nbSortants')" "2"
assert_eq "T7.7 nombre de liens entrants" "$(E "$O6" vf-coder/b.md 'e.nbEntrants')" "1"

echo "T7.8 — borne"
L7="$WORK/l7"; lab_init "$L7"
idx "$L7" vf-coder '- [A](a.md)'
for n in a b c d; do mem "$L7" vf-coder "$n.md" "entree-$n" project 'rien'; done
gc "$L7" 2026-01-10 'quatre'
assert_eq "T7.8 sans borne : quatre entrées, non tronqué" "$(J "$(V "$L7")" "[j.entrees.length,j.tronque]")" "[4,false]"
assert_eq "T7.8 max 2 : deux entrées lues, tronqué" "$(J "$(V "$L7" 2)" "[j.entrees.length,j.tronque]")" "[2,true]"

echo
echo "=== T8 — liens et états ==="
echo "T8.1 — extraction des liens"
L8="$WORK/l8"; lab_init "$L8"
idx "$L8" vf-coder '- [A](a.md) [B](b.md)'
wr "$L8/.claude/agent-memory/vf-coder/a.md" <<'MD'
---
name: entree-a
metadata:
  type: project
---

voir [[entree-b]] hors code, et une classe [[:alpha:]] dans un test.

```
[[dans-bloc]]
```

et `[[entre-accents]]` en ligne.
MD
mem "$L8" vf-coder b.md entree-b project 'rien'
gc "$L8" 2026-01-10 'extraction'
O8="$(V "$L8")"
assert_eq "T8.1 témoin positif : les trois formes ignorées sont dans le fichier" "$(grep -c -e 'dans-bloc' -e 'entre-accents' -e ':alpha:' "$L8/.claude/agent-memory/vf-coder/a.md")" "3"
assert_eq "T8.1 seul le lien hors code est retenu" "$(E "$O8" vf-coder/a.md 'e.sortants.map(s=>s.cible)')" '["entree-b"]'

echo "T8.2 — résolution en deux temps"
L9="$WORK/l9"; lab_init "$L9"
idx "$L9" vf-coder '- [A](a.md) [B](b.md) [C](c.md)'
idx "$L9" vf-reviewer '- [X](x.md)'
mem "$L9" vf-coder a.md entree-a project 'liens [[entree-b]] [[c]] [[inconnu]] [[partage]]'
mem "$L9" vf-coder b.md entree-b project 'rien'
mem "$L9" vf-coder c.md autre-nom-c project 'rien'
mem "$L9" vf-reviewer x.md partage project 'rien'
gc "$L9" 2026-01-10 'résolution'
O9="$(V "$L9")"
assert_eq "T8.2 états dans l'ordre de citation" "$(E "$O9" vf-coder/a.md 'e.sortants.map(s=>s.etat)')" '["resolu","resolu-par-nom","casse","resolu"]'
assert_eq "T8.2 cible par nom de fichier" "$(E "$O9" vf-coder/a.md 'e.sortants[1].vers')" "vf-coder/c.md"
assert_eq "T8.2 name unique d'un autre agent du lab" "$(E "$O9" vf-coder/a.md 'e.sortants[3].vers')" "vf-reviewer/x.md"
assert_eq "T8.2 compteurs resolusParNom et liensCasses du lab" "$(J "$O9" "[j.compteurs.resolusParNom,j.compteurs.liensCasses]")" "[1,1]"
assert_eq "T8.2 compteurs de l'agent" "$(J "$O9" "(a=>[a.resolusParNom,a.liensCasses,a.entrees])(j.agents.find(x=>x.agent==='vf-coder'))")" "[1,1,3]"

echo "T8.3 — hors index, égalité exacte du nom de fichier"
L10="$WORK/l10"; lab_init "$L10"
idx "$L10" vf-coder '- [AA](aa.md) — cité
- [B](./b.md) — cité avec ./'
for n in a aa b; do mem "$L10" vf-coder "$n.md" "entree-$n" project 'rien'; done
gc "$L10" 2026-01-10 'index'
O10="$(V "$L10")"
assert_eq "T8.3 a.md hors index (aa.md ne l'indexe pas)" "$(E "$O10" vf-coder/a.md 'e.horsIndex')" "true"
assert_eq "T8.3 aa.md indexé" "$(E "$O10" vf-coder/aa.md 'e.horsIndex')" "false"
assert_eq "T8.3 b.md indexé malgré le ./ initial" "$(E "$O10" vf-coder/b.md 'e.horsIndex')" "false"
assert_eq "T8.3 compteur horsIndex" "$(J "$O10" "j.compteurs.horsIndex")" "1"

echo "T8.4 — sans lien entrant"
L11="$WORK/l11"; lab_init "$L11"
idx "$L11" vf-coder '- [X](x.md) [Y](y.md) [Z](z.md)'
mem "$L11" vf-coder x.md entree-x project 'se cite [[entree-x]]'
mem "$L11" vf-coder y.md entree-y project 'rien'
mem "$L11" vf-coder z.md entree-z project 'cite [[entree-y]]'
gc "$L11" 2026-01-10 'entrants'
O11="$(V "$L11")"
assert_eq "T8.4 citée par l'index et par elle-même : sans lien entrant" "$(E "$O11" vf-coder/x.md 'e.sansEntrant')" "true"
assert_eq "T8.4 citée par une autre entrée : avec lien entrant" "$(E "$O11" vf-coder/y.md 'e.sansEntrant')" "false"
assert_eq "T8.4 compteur sansEntrant (x et z)" "$(J "$O11" "j.compteurs.sansEntrant")" "2"

echo "T8.5 — chemin cité absent de HEAD, présent dans l'historique"
L12="$WORK/l12"; lab_init "$L12"
mkdir -p "$L12/docs"; printf 'v\n' > "$L12/docs/vieux.md"; printf 'a\n' > "$L12/docs/ancien.md"
idx "$L12" vf-coder '- [A](a.md)'
mem "$L12" vf-coder a.md entree-a project 'cite docs/vieux.md, `docs/ancien.md`, docs/jamais.md et docs/nouveau.md.'
gc "$L12" 2026-01-01 'début'
git -C "$L12" rm -q docs/vieux.md; gc "$L12" 2026-01-02 'suppression'
git -C "$L12" mv docs/ancien.md docs/nouveau.md; gc "$L12" 2026-01-03 'déplacement'
O12="$(V "$L12")"
assert_eq "T8.5 témoin positif : jamais.md n'est ni dans HEAD ni dans l'historique" "$(git -C "$L12" log --all --name-only --format= | grep -c 'docs/jamais.md')" "0"
assert_eq "T8.5 supprimé et déplacé listés, relatifs, triés" "$(E "$O12" vf-coder/a.md 'e.cheminsAbsents')" '["docs/ancien.md","docs/vieux.md"]'
assert_eq "T8.5 compteur : deux chemins distincts" "$(J "$O12" "j.compteurs.cheminsAbsents")" "2"

echo "T8.6 — aucune péremption"
L13="$WORK/l13"; lab_init "$L13"
idx "$L13" vf-coder '- [A](a.md) [B](b.md)'
mem "$L13" vf-coder a.md entree-a project 'rien'; gc "$L13" 2025-01-01 'vieille'
mem "$L13" vf-coder b.md entree-b project 'rien'; gc "$L13" 2026-11-01 'récente'
O13="$(V "$L13")"
assert_eq "T8.6 témoin positif : deux jours distincts lus" "$(J "$O13" "[j.entrees[0].jour,j.entrees[1].jour]")" '["2025-01-01","2026-11-01"]'
assert_eq "T8.6 aucune clé perim* à aucune profondeur" "$(J "$O13" "(function f(o){return !!o&&typeof o==='object'&&Object.keys(o).some(k=>/^perim/i.test(k)||f(o[k]))})(j)")" "false"
assert_eq "T8.6 l'entrée d'un an n'a aucun état de plus que la récente" "$(J "$O13" "Object.keys(j.entrees[0]).join()===Object.keys(j.entrees[1]).join()")" "true"

echo "T8.7 — dépôt réel (lecture seule)"
OR="$(V "$REPO" reel)"
assert_eq "T8.7 témoin positif : le dépôt porte des descriptions dans ses fichiers de mémoire" "$(git -C "$REPO" ls-files '.claude/agent-memory/' | head -400 | xargs grep -l '^description:' 2>/dev/null | head -1 | wc -c | tr -d ' ' | awk '{print ($1>0)?"oui":"non"}')" "oui"
assert_eq "T8.7 au moins une entrée et un lien" "$(J "$OR" "[j.entrees.length>0,j.entrees.some(e=>e.nbSortants>0)]")" "[true,true]"
assert_eq "T8.7 aucune clé description, corps ni texte" "$(J "$OR" "(function f(o){return !!o&&typeof o==='object'&&Object.keys(o).some(k=>/^(description|corps|texte)\$/i.test(k)||f(o[k]))})(j)")" "false"
assert_eq "T8.7 aucune occurrence du chemin absolu de la racine" "$(SANS "$OR" "$REPO")" "ok"

echo
echo "=== Bilan : $PASS passés, $FAIL échoués ==="
[ "$FAIL" -eq 0 ]
