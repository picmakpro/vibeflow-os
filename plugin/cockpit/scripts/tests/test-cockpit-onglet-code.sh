#!/usr/bin/env bash
# test-cockpit-onglet-code.sh — onglet Code conditionnel, sans modèle (CKPT-06, volet Code ; P67-D-17).
#   C1 lab à modules : extracteur VibeFlow (dispatch, source, plus de liens que le même lab en brut)
#   C4 dossier de plugin/ sans module.json : nœud infra générique + enfant tests (sans liste de noms)
#   C2 lab neutre : architecture brute · C3 aucun assemblage n'appelle `claude` (faux binaire consignant tout appel)
#   C5 accord de « fichier de code » dans le résumé d'un dossier : 1 fichier, 2 fichiers (UIFN-06, 70-01)
# Labs jetables dans mktemp, isolation git, HOME jetable. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"; mkdir -p "$WORK/aux" "$WORK/home" "$WORK/fake"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"
export HOME="$WORK/home"
trap '[ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_gt() { if [ "${2:-0}" -gt "$3" ] 2>/dev/null; then echo "  ✅ PASS — $1 ($2 > $3)"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 ($2 ≤ $3)"; FAIL=$((FAIL+1)); fi; }

cat > "$AUX/donnees.mjs" <<'JS'
// donnees.mjs <dossier de scripts du module> <page> <expression sur j> : lit la zone de données par vf-cockpit-embed.mjs du module
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const { extraireGraphe } = await import(pathToFileURL(path.join(process.argv[2], 'vf-cockpit-embed.mjs')).href);
const j = extraireGraphe(fs.readFileSync(process.argv[3], 'utf8'));
const v = new Function('j', 'return (' + process.argv[4] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
# faux claude : consigne tout appel
NODE="$(command -v node)"; printf '#!%s\nrequire("fs").appendFileSync(process.env.VF_FAKE_LOG, process.argv.slice(2).join(" ") + "\\n");\n' "$NODE" > "$WORK/fake/claude"; chmod +x "$WORK/fake/claude"
export VF_FAKE_LOG="$WORK/appels.log"

mklab() { # mklab <dossier> modules|neutre
  local L="$1"; mkdir -p "$L/.planning/phases/01-x" "$L/src"
  printf -- '- [x] **Phase 1: Socle** - premier jet\n' > "$L/.planning/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$L/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$L/.planning/phases/01-x/01-01-SUMMARY.md"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"
  if [ "$2" = modules ]; then
    mkdir -p "$L/plugin/a/agents" "$L/plugin/a/scripts" "$L/plugin/a/skills/k" "$L/plugin/b/agents"
    printf '{"name":"a","version":"1.0.0","type":"agent + skills + scripts","description":"Module A de test."}\n' > "$L/plugin/a/module.json"
    printf '{"name":"b","version":"1.0.0","type":"doc-only","description":"Module B de test."}\n' > "$L/plugin/b/module.json"
    printf -- '---\nname: x\ndescription: agent x\ntools: Read, Agent(y)\n---\nCorps de x.\n' > "$L/plugin/a/agents/x.md"
    printf -- '---\nname: y\ndescription: agent y\ntools: Read\n---\nCorps de y.\n' > "$L/plugin/b/agents/y.md"
    printf '#!/usr/bin/env bash\nsource ./s2.sh\necho s1\n' > "$L/plugin/a/scripts/s1.sh"
    printf '#!/usr/bin/env bash\necho s2\n' > "$L/plugin/a/scripts/s2.sh"
    printf -- '---\nname: k\ndescription: skill k\n---\nLancer `s1.sh` pour la preuve.\n' > "$L/plugin/a/skills/k/SKILL.md"
  fi
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
}
assembler() { PATH="$WORK/fake:$PATH" node "$SCRIPTS/vf-cockpit-build.mjs" "$1" --quiet > "$WORK/build.out" 2>&1; echo $?; }
donnee() { node "$AUX/donnees.mjs" "$SCRIPTS" "$1/.vibeflow/cockpit/index.html" "$2"; }

echo "=== C1 — lab à modules : extracteur VibeFlow ==="
LM="$WORK/modules"; mklab "$LM" modules
assert_eq "C1.1 — l'assemblage rend 0" "$(assembler "$LM")" "0"
assert_eq "C1.2 — meta.vfCodeExtractor = vibeflow" "$(donnee "$LM" 'j.meta.vfCodeExtractor')" "vibeflow"
assert_eq "C1.3 — un lien call de x vers y (dispatch Agent)" "$(donnee "$LM" 'j.links.filter(l=>l.k==="call"&&l.a==="f:plugin/a/agents/x.md"&&l.b==="f:plugin/b/agents/y.md").length')" "1"
assert_eq "C1.4 — un lien import de s1 vers s2 (source)" "$(donnee "$LM" 'j.links.filter(l=>l.k==="import"&&l.a==="f:plugin/a/scripts/s1.sh"&&l.b==="f:plugin/a/scripts/s2.sh").length')" "1"
assert_eq "C1.5 — un lien call du skill vers s1 (mention de script)" "$(donnee "$LM" 'j.links.filter(l=>l.k==="call"&&l.a==="f:plugin/a/skills/k/SKILL.md"&&l.b==="f:plugin/a/scripts/s1.sh").length')" "1"
assert_eq "C1.6 — la nature d'un module est lue dans son module.json (a : agents, b : doc-only)" "$(donnee "$LM" 'j.nodes.filter(n=>n.id==="m-a"||n.id==="m-b").map(n=>n.kind).join(",")')" "service,config"
NV=$(donnee "$LM" 'j.links.length')
# témoin : le même lab dont les module.json sont renommés -> architecture brute
LB="$WORK/brut"; mklab "$LB" modules; for m in a b; do git -C "$LB" mv "plugin/$m/module.json" "plugin/$m/module.json.off"; done; git -C "$LB" -c user.email=t@t -c user.name=t commit -q -m off
assert_eq "C1.7 — témoin : sans module.json le même lab est assemblé en brut" "$(assembler "$LB")$(donnee "$LB" 'j.meta.vfCodeExtractor')" "0brut"
assert_gt "C1.8 — l'extracteur VibeFlow produit strictement plus de liens que le brut sur le même lab" "$NV" "$(donnee "$LB" 'j.links.length')"

echo "=== C4 — dossier de plugin/ sans module.json (installeur, commandes…) ==="
LI="$WORK/interne"; mklab "$LI" modules
mkdir -p "$LI/plugin/c/tests" "$LI/plugin/c/lib" "$LI/plugin/d/tests/fixtures"
printf '#!/usr/bin/env bash\necho c\n' > "$LI/plugin/c/run.sh"; printf '#!/usr/bin/env bash\necho t\n' > "$LI/plugin/c/tests/t.sh"; printf '#!/usr/bin/env bash\necho l\n' > "$LI/plugin/c/lib/l.sh"
printf '#!/usr/bin/env bash\necho f\n' > "$LI/plugin/d/tests/fixtures/f.sh"
git -C "$LI" add -A && git -C "$LI" -c user.email=t@t -c user.name=t commit -q -m interne
assert_eq "C4.1 — l'assemblage rend 0" "$(assembler "$LI")" "0"
assert_eq "C4.2 — un dossier sans module.json qui porte des fichiers a un nœud infra, sans version" "$(donnee "$LI" 'j.nodes.filter(n=>n.id==="m-c").map(n=>n.kind+"|"+n.label+"|"+(n.tags||[]).length).join(",")')" "infra|c|0"
assert_eq "C4.3 — son sous-dossier tests direct est un enfant de kind test" "$(donnee "$LI" 'j.nodes.filter(n=>n.id==="m-c.tests").map(n=>n.kind+"|"+n.parent).join(",")')" "test|m-c"
assert_eq "C4.4 — aucun fichier de ce dossier ne reste dans unassigned" "$(donnee "$LI" 'j.files.filter(f=>f.n==="unassigned"&&f.p.startsWith("plugin/c/")).length')" "0"
assert_eq "C4.5 — un dossier sans module.json qui ne porte que des fichiers ignorés n'a aucun nœud" "$(donnee "$LI" 'j.nodes.filter(n=>n.id==="m-d").length')" "0"
assert_eq "C4.6 — les modules existants gardent leur nature (a : agents, b : doc-only)" "$(donnee "$LI" 'j.nodes.filter(n=>n.id==="m-a"||n.id==="m-b").map(n=>n.kind).join(",")')" "service,config"

echo "=== C2 — lab neutre : architecture brute ==="
LN="$WORK/neutre"; mklab "$LN" neutre
assert_eq "C2.1 — l'assemblage rend 0" "$(assembler "$LN")" "0"
assert_eq "C2.2 — meta.vfCodeExtractor = brut" "$(donnee "$LN" 'j.meta.vfCodeExtractor')" "brut"

echo "=== C5 — accord de « fichier de code » dans le résumé d'un dossier (UIFN-06, 70-01) ==="
LA="$WORK/accord"; mklab "$LA" neutre
mkdir -p "$LA/solo" "$LA/duo"; printf 'export const a = 1;\n' > "$LA/solo/a.js"; printf 'export const a = 1;\n' > "$LA/duo/a.js"; printf 'export const b = 2;\n' > "$LA/duo/b.js"
git -C "$LA" add -A && git -C "$LA" -c user.email=t@t -c user.name=t commit -q -m accord
assert_eq "C5.0 — l'assemblage du lab d'accord rend 0" "$(assembler "$LA")" "0"
assert_eq "C5.1 — un dossier à un seul fichier de code : « 1 fichier de code » (jamais « 1 fichiers »)" "$(donnee "$LA" 'j.nodes.filter(n=>n.label==="solo").map(n=>n.summary).join("|")')" "Dossier solo : 1 fichier de code."
assert_eq "C5.2 — un dossier à deux fichiers : « 2 fichiers de code »" "$(donnee "$LA" 'j.nodes.filter(n=>n.label==="duo").map(n=>n.summary).join("|")')" "Dossier duo : 2 fichiers de code."

echo "=== C6 — recette 2026-11-04 : un texte affiché n'est jamais coupé en plein mot (P70-D-02, P70-D-04) ==="
# 6 : la première phrase de la description d'un module (texte d'une étape de la visite) est entière, même longue ; seule la 2e phrase est écartée
LONG="Ce module reçoit les escalades des gestionnaires de mission, les trie par gravité, les confie au bon exécutant puis rend un rapport compact à la session principale pour décision humaine."
LV="$WORK/phrase"; mklab "$LV" modules
printf '{"name":"a","version":"1.0.0","type":"agent + skills + scripts","description":"%s Une seconde phrase."}\n' "$LONG" > "$LV/plugin/a/module.json"
git -C "$LV" add -A && git -C "$LV" -c user.email=t@t -c user.name=t commit -q -m long
assert_eq "C6.0 — l'assemblage rend 0" "$(assembler "$LV")" "0"
assert_eq "C6.1 — la phrase de plus de 170 caractères reste entière, sans la seconde phrase" "$(donnee "$LV" 'j.nodes.filter(n=>n.id==="m-a").map(n=>n.summary).join("|")')" "$LONG"
# 5b : le titre du travail récent (sous-titre du tableau) n'est pas coupé à 60 caractères en plein mot
TITRE="Socle du découpage et de la validation des gabarits de la couche française"
LT="$WORK/recent"; mklab "$LT" neutre
printf -- '- [x] **Phase 1: %s** - premier jet\n' "$TITRE" > "$LT/.planning/ROADMAP.md"
printf -- '---\nfiles_modified: [src/util.js]\n---\n<objective>Faire le socle</objective>\n' > "$LT/.planning/phases/01-x/01-01-PLAN.md"
git -C "$LT" add -A && git -C "$LT" -c user.email=t@t -c user.name=t commit -q -m titre
assert_eq "C6.2 — l'assemblage rend 0" "$(assembler "$LT")" "0"
assert_eq "C6.3 — le titre du travail récent est entier (jamais coupé à 60 caractères)" "$(node -e 'const t=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).tasks;console.log(t.length+"|"+(t[0]||{}).title)' "$LT/.vibeflow/cockpit/recent-work.json")" "1|Phase 1 · $TITRE"

echo "=== C7 — résumés de fichiers : ni « > » initial, ni HTML brut, texte sans accents marqué « extrait brut » (PU-G-067, PU-G-068) ==="
LR="$WORK/resumes"; mklab "$LR" modules; mkdir -p "$LR/plugin/a/references"
printf '# Titre\n\n> Une citation de tête qui sert de résumé à ce fichier de référence.\n> Sa seconde ligne continue la citation.\n' > "$LR/plugin/a/references/citation.md"
printf '<picture>\n  <source media="(prefers-color-scheme: dark)" srcset="logo-dark.svg">\n  <img alt="logo" src="logo.svg">\n</picture>\n\nLe texte lisible du fichier commence ici, après le balisage.\n' > "$LR/plugin/a/references/balise.md"
printf '# Titre\n\nLancer <lab> puis lire <chemin> avant de continuer le travail demandé.\n' > "$LR/plugin/a/references/prose.md"
printf '# Titre\n\nUne regle auto-scopee est une convention chargee sur certains fichiers, a chaque etape.\n' > "$LR/plugin/a/references/sans-accent.md"
printf '# Title\n\nThis reference is complete and different from the other one in every detail.\n' > "$LR/plugin/a/references/anglais.md"
git -C "$LR" add -A && git -C "$LR" -c user.email=t@t -c user.name=t commit -q -m resumes
assert_eq "C7.0 — l'assemblage rend 0" "$(assembler "$LR")" "0"
desc() { donnee "$LR" "(j.files.find(f=>f.p==='plugin/a/references/$1')||{}).d"; }
assert_eq "C7.1 — citation : le « > » initial est retiré, première phrase entière" "$(desc citation.md)" "Une citation de tête qui sert de résumé à ce fichier de référence."
assert_eq "C7.2 — HTML brut : le résumé est le premier texte lisible, sans balise" "$(desc balise.md)" "Le texte lisible du fichier commence ici, après le balisage."
assert_eq "C7.3 — un « <lab> » de la prose reste intact (liste fermée de balises)" "$(desc prose.md)" "Lancer <lab> puis lire <chemin> avant de continuer le travail demandé."
assert_eq "C7.4 — texte sans accents : conservé tel quel, marqué « extrait brut »" "$(desc sans-accent.md)" "Une regle auto-scopee est une convention chargee sur certains fichiers, a chaque etape. (extrait brut)"
assert_eq "C7.5 — texte anglais sans accents : jamais marqué (mots français seulement)" "$(desc anglais.md)" "This reference is complete and different from the other one in every detail."
assert_eq "C7.6 — aucun résumé de l'index ne commence par « > » ou « < »" "$(donnee "$LR" 'j.files.filter(f=>f.d&&/^[<>]/.test(f.d)).length')" "0"

echo "=== C3 — aucun appel à claude pendant l'assemblage ==="
assert_eq "C3.1 — le faux claude n'a été appelé par aucun assemblage (C1, C2 et le témoin)" "$([ -s "$VF_FAKE_LOG" ] && wc -l < "$VF_FAKE_LOG" | tr -d ' ' || echo 0)" "0"
PATH="$WORK/fake:$PATH" claude --version
assert_eq "C3.2 — témoin : le même faux binaire appelé directement consigne bien un appel" "$([ -s "$VF_FAKE_LOG" ] && wc -l < "$VF_FAKE_LOG" | tr -d ' ' || echo 0)" "1"

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then
  echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"
  exit 1
fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
