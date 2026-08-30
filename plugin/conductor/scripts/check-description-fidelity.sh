#!/usr/bin/env bash
# check-description-fidelity.sh — Gate ET convertisseur de la description: de frontmatter
# (Phase 38, prolongement FIDE-01/FIDE-02, plan 38-08). Source unique de la logique de double
# vérification : la MÊME fonction d'égalité sert au mode audit, à --inventory (classification,
# aucune écriture) et à --fix (conversion en place) — un convertisseur jetable rouvrirait la
# dérive que ce lot ferme.
#
# Deux chemins de lecture mesurés, sur CHAQUE description: de frontmatter de premier niveau :
#   Passe A — un vrai parseur YAML strict (PyYAML, une seule invocation python3 sur l'ensemble
#     des fichiers découverts, jamais un processus par fichier).
#   Passe B — la logique gsd-core reproduite VERBATIM sous node, et nulle part ailleurs :
#     extractFrontmatterField (bin/lib/runtime-artifact-conversion.cjs:924-930) —
#     `new RegExp("^description:\s*(.+)$", 'm')` puis `.trim().replace(/^['"]|['"]$/g, '')`.
#     Le quantificateur `\s*` est la classe d'espaces JS (traverse les fins de ligne), PAS
#     `[ \t]*` : une approximation Python ou bash ne reproduit pas ce comportement.
#
# Règle de verdict par fichier (une PROPRIÉTÉ, jamais une forme) :
#   1. la passe A doit réussir (frontmatter désérialisable) ;
#   2. la valeur rendue par la passe B doit être égale, caractère pour caractère, à celle rendue
#      par la passe A.
#
# Usage:
#   check-description-fidelity.sh [--root <dir>]              # mode audit (défaut)
#   check-description-fidelity.sh --inventory [--root <dir>]  # classification TSV, aucune écriture
#   check-description-fidelity.sh --fix [--root <dir>]        # conversion en place
#   check-description-fidelity.sh --help
#
# Périmètre de découverte : tout fichier .md sous --root (défaut <racine-du-dépôt>/plugin, dérivée
# de l'emplacement de ce script — jamais du cwd) dont la première ligne est un délimiteur de
# frontmatter ET dont le frontmatter porte une clé description: de PREMIER NIVEAU (colonne 0).
# Une occurrence de description: dans le CORPS du markdown est hors périmètre, exclue
# structurellement par la découverte (jamais par filtrage a posteriori).
#
# Forme cible (arbitrée en amont) : scalaire mono-ligne entre guillemets doubles, texte
# strictement inchangé — `description: "texte mono-ligne, avec: des deux-points, entre guillemets"`.
# Guillemets simples uniquement si le texte contient un guillemet double MAIS aucune apostrophe.
# Un texte qui contient les deux n'est PAS modifié : il devient une exception nommée.
#
# Liste d'exceptions nommées (déclarée ci-dessous, EXCEPTIONS_REL/EXCEPTIONS_REASON) : un cliquet.
# Le gate ÉCHOUE si une entrée pointe un fichier absent, ou si un fichier exempté satisferait
# désormais les deux règles (exception périmée, à retirer). Les exceptions sont imprimées à
# CHAQUE exécution, jamais un skip muet. Override de test : CDF_EXCEPTIONS_FILE (TSV
# chemin-relatif-a-ROOT<TAB>raison), utilisé par la suite de tests sur fixtures isolées.
#
# Sonde runtime (Tâche 2, mandat point c) — conclusion MESURÉE le 2026-08-30, sans le moindre
# appel modèle (`kimi --version`, `kimi --help`, `kimi doctor --help`, `kimi provider --help`,
# `kimi migrate --help` — cinq invocations locales, aucune ne charge de session ni ne consomme de
# jeton) : le binaire `kimi` (@moonshot-ai/kimi-code 0.39.1) est présent sur ce poste. Candidats
# examinés et motif de rejet de CHACUN :
#   - `--agent-file <path>` (aide racine) : charge réellement un fichier d'agent, mais OUVRE UNE
#     SESSION (exige une authentification, un appel modèle potentiel) — rejeté, pas sans coût.
#   - `kimi doctor` : sous-commandes `config` et `tui` UNIQUEMENT — valide config.toml/tui.toml,
#     jamais un fichier d'agent — rejeté, hors-cible.
#   - `kimi provider`, `kimi migrate`, `kimi export`, `kimi acp`, `kimi web`, `kimi vis` : aucun
#     rapport, par leur description propre, à la validation d'un fichier d'agent — rejetés,
#     hors-cible (examinés par lecture de leur aide, `provider`/`migrate` vérifiés en détail).
# CONCLUSION : aucune sonde sans coût n'existe côté kimi-code pour valider un frontmatter d'agent.
# Rien n'est donc câblé ici. La passe A (PyYAML strict) tient lieu de substitut FONCTIONNELLEMENT
# ÉQUIVALENT POUR LA PROPRIÉTÉ TESTÉE (un frontmatter que PyYAML refuse est un frontmatter que
# tout désérialiseur YAML strict refuse) — ce n'est PAS une preuve d'acceptation par kimi-code
# lui-même. Aucune formulation de ce gate ne doit se lire comme « testé sur kimi ». Détail complet
# de l'examen (trace commande par commande) dans 38-08-SUMMARY.md.
#
# Exit codes:
#   0 = PASS (audit) — tous les fichiers non exemptés satisfont les deux règles, aucune exception
#       périmée. --inventory et --fix rendent aussi 0 en régime nominal.
#   1 = FAIL — au moins un fichier viole une règle, ou une exception est périmée/orpheline ; le
#       rapport nomme le fichier, la règle violée, la valeur attendue et la valeur obtenue.
#   2 = erreur d'usage (argument inconnu, --fix et --inventory combinés).
#   3 = INDÉTERMINÉ bruyant — python3, le module YAML strict ou node indisponible, OU zéro fichier
#       découvert sous --root. Un vert sur une cible vide serait un faux vert : refusé explicitement.
set -uo pipefail

MODE="audit"
ROOT=""
INVENTORY_FLAG=0
FIX_FLAG=0

SCRIPT_PATH="$0"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --inventory)
      INVENTORY_FLAG=1
      shift
      ;;
    --fix)
      FIX_FLAG=1
      shift
      ;;
    --root)
      ROOT="${2:-}"
      shift 2
      ;;
    --root=*)
      ROOT="${1#*=}"
      shift
      ;;
    -h|--help)
      grep '^# ' "$0" | sed 's/^# //'
      exit 0
      ;;
    *)
      echo "[check-description-fidelity] argument inconnu : $1" >&2
      exit 2
      ;;
  esac
done

if [ "$INVENTORY_FLAG" -eq 1 ] && [ "$FIX_FLAG" -eq 1 ]; then
  echo "[check-description-fidelity] --inventory et --fix ne se combinent pas (deux modes exclusifs)" >&2
  exit 2
fi

if [ "$FIX_FLAG" -eq 1 ]; then
  MODE="fix"
elif [ "$INVENTORY_FLAG" -eq 1 ]; then
  MODE="inventory"
fi

if [ -z "$ROOT" ]; then
  ROOT="$REPO_ROOT/plugin"
fi
if [ ! -d "$ROOT" ]; then
  echo "[check-description-fidelity] --root introuvable : $ROOT" >&2
  exit 3
fi
ROOT="$(cd "$ROOT" && pwd)"

# --- Liste d'exceptions nommées (cliquet) — chemins RELATIFS à ROOT. Re-dérivées par
# --inventory sur l'arbre réel avant d'être figées ici (cf. SUMMARY pour la mesure de cadrage).
EXCEPTIONS_REL=(
  "consolidator/SKILL.md"
  "design-orchestrator/AGENT.md"
  "reference/content/methodology/templates/skills/safe-execute/SKILL.md"
)
EXCEPTIONS_REASON=(
  "contient à la fois un guillemet double ET une apostrophe — aucune forme quotée ne traverse les deux consommateurs à l'identique"
  "contient à la fois un guillemet double ET une apostrophe — aucune forme quotée ne traverse les deux consommateurs à l'identique"
  "contient à la fois un guillemet double ET une apostrophe — aucune forme quotée ne traverse les deux consommateurs à l'identique"
)
if [ -n "${CDF_EXCEPTIONS_FILE:-}" ]; then
  if [ ! -f "$CDF_EXCEPTIONS_FILE" ]; then
    echo "[check-description-fidelity] CDF_EXCEPTIONS_FILE introuvable : $CDF_EXCEPTIONS_FILE" >&2
    exit 2
  fi
  EXCEPTIONS_REL=()
  EXCEPTIONS_REASON=()
  while IFS=$'\t' read -r rel reason; do
    [ -n "$rel" ] || continue
    EXCEPTIONS_REL+=("$rel")
    EXCEPTIONS_REASON+=("$reason")
  done < "$CDF_EXCEPTIONS_FILE"
fi

TMPDIR_GATE="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_GATE"' EXIT

# --- Découverte (bash/awk pur, indépendante de python3/node — la découverte doit fonctionner
# même quand un interpréteur est neutralisé, pour que les deux conditions d'INDÉTERMINÉ restent
# distinguables). Exclut structurellement le corps du markdown : décision prise à la fermeture du
# frontmatter, jamais par un filtrage a posteriori sur le fichier entier. ---
discover_files() {
  local root="$1"
  find "$root" -type f -name '*.md' 2>/dev/null | LC_ALL=C sort | while IFS= read -r f; do
    if awk '
      NR==1 { if ($0 !~ /^---[[:space:]]*$/) exit 1; next }
      /^---[[:space:]]*$/ { closed=1; exit (found ? 0 : 1) }
      /^description:/ { found=1 }
      END { if (!closed) exit 1 }
    ' "$f"; then
      printf '%s\n' "$f"
    fi
  done
}

FILES="$(discover_files "$ROOT")"
if [ -z "$FILES" ]; then
  FILE_COUNT=0
else
  FILE_COUNT=$(printf '%s\n' "$FILES" | wc -l | tr -d ' ')
fi

if [ "$FILE_COUNT" -eq 0 ]; then
  echo "[check-description-fidelity] INDÉTERMINÉ : aucun fichier découvert sous $ROOT (cible vide — refus du vert à vide)" >&2
  exit 3
fi

# --- Vérification des interpréteurs — APRÈS la découverte (qui n'en dépend pas), AVANT toute
# invocation des passes. Un vert sans ces deux moteurs serait un faux vert. ---
if ! command -v python3 >/dev/null 2>&1; then
  echo "[check-description-fidelity] INDÉTERMINÉ : python3 introuvable (passe A, parseur YAML strict)" >&2
  exit 3
fi
if ! python3 -c 'import yaml' >/dev/null 2>&1; then
  echo "[check-description-fidelity] INDÉTERMINÉ : module PyYAML introuvable pour python3 (passe A)" >&2
  exit 3
fi
if ! command -v node >/dev/null 2>&1; then
  echo "[check-description-fidelity] INDÉTERMINÉ : node introuvable (passe B, reproduction gsd-core)" >&2
  exit 3
fi

FILELIST="$TMPDIR_GATE/files.txt"
printf '%s\n' "$FILES" > "$FILELIST"

# =====================================================================================
# Passe A — parseur YAML strict (python3/PyYAML). Une seule invocation sur l'ensemble des
# fichiers découverts. TSV en sortie : chemin<TAB>OK|ERR<TAB>base64(valeur ou message d'erreur).
# =====================================================================================
PASS_A_PY="$TMPDIR_GATE/pass_a.py"
cat > "$PASS_A_PY" << 'PYEOF'
import sys, base64
import yaml


def b64(s):
    return base64.b64encode(s.encode('utf-8', 'surrogateescape')).decode('ascii')


for line in sys.stdin:
    path = line.rstrip('\n')
    if not path:
        continue
    try:
        with open(path, 'r', encoding='utf-8') as fh:
            content = fh.read()
    except Exception as e:
        print(path + "\tERR\t" + b64("lecture: " + str(e)))
        continue
    lines = content.split('\n')
    if not lines or lines[0].strip() != '---':
        print(path + "\tERR\t" + b64("premiere ligne != ---"))
        continue
    end_idx = None
    for i in range(1, len(lines)):
        if lines[i].strip() == '---':
            end_idx = i
            break
    if end_idx is None:
        print(path + "\tERR\t" + b64("delimiteur de fermeture --- absent"))
        continue
    fm_text = '\n'.join(lines[1:end_idx])
    try:
        data = yaml.safe_load(fm_text)
    except yaml.YAMLError as e:
        msg = str(e).replace('\n', ' | ')
        print(path + "\tERR\t" + b64(msg))
        continue
    if not isinstance(data, dict) or 'description' not in data or data.get('description') is None:
        print(path + "\tERR\t" + b64("description absente du frontmatter desserialise"))
        continue
    val = data['description']
    text = str(val)
    text = text.replace('\n', ' ')
    text = text.rstrip()
    print(path + "\tOK\t" + b64(text))
PYEOF

# =====================================================================================
# Passe B — logique gsd-core reproduite VERBATIM (node). Une seule invocation sur le même
# ensemble. TSV en sortie : chemin<TAB>OK|ERR<TAB>base64(valeur)<TAB>style(LINE|BLOCK|NA)
# <TAB>base64(texte brut avant dé-quotage — utilisé comme texte de référence pour un scalaire
# plain, cf. cas limites de --inventory/--fix).
# =====================================================================================
PASS_B_JS="$TMPDIR_GATE/pass_b.js"
cat > "$PASS_B_JS" << 'JSEOF'
const fs = require('fs');

function b64(s) {
  return Buffer.from(s, 'utf8').toString('base64');
}

let buf = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (d) => { buf += d; });
process.stdin.on('end', () => {
  const paths = buf.split('\n').map((s) => s.trim()).filter(Boolean);
  const out = [];
  for (const p of paths) {
    let content;
    try {
      content = fs.readFileSync(p, 'utf8');
    } catch (e) {
      out.push(`${p}\tERR\t${b64('lecture: ' + e.message)}\tNA\t${b64('')}`);
      continue;
    }
    // Reproduction verbatim de extractFrontmatterAndBody
    // (gsd-core bin/lib/runtime-artifact-conversion.cjs:911-921).
    if (!content.startsWith('---')) {
      out.push(`${p}\tERR\t${b64('frontmatter delimiter absent')}\tNA\t${b64('')}`);
      continue;
    }
    const endIndex = content.indexOf('---', 3);
    if (endIndex === -1) {
      out.push(`${p}\tERR\t${b64('delimiteur de fermeture --- absent')}\tNA\t${b64('')}`);
      continue;
    }
    const frontmatter = content.substring(3, endIndex).trim();
    // Reproduction verbatim de extractFrontmatterField
    // (gsd-core bin/lib/runtime-artifact-conversion.cjs:924-930). \s* = classe d'espaces JS
    // (traverse les fins de ligne), PAS [ \t]* — piège en ciseaux nommé au cadrage.
    const regex = new RegExp('^description:\\s*(.+)$', 'm');
    const match = frontmatter.match(regex);
    if (!match) {
      out.push(`${p}\tERR\t${b64('description absente (regex gsd-core)')}\tNA\t${b64('')}`);
      continue;
    }
    const raw = match[1];
    const value = raw.trim().replace(/^['"]|['"]$/g, '');
    const rawTrimmed = raw.trim();
    const style = (rawTrimmed[0] === '>' || rawTrimmed[0] === '|') ? 'BLOCK' : 'LINE';
    out.push(`${p}\tOK\t${b64(value)}\t${style}\t${b64(raw)}`);
  }
  process.stdout.write(out.join('\n') + (out.length ? '\n' : ''));
});
JSEOF

A_TSV="$TMPDIR_GATE/pass_a.tsv"
B_TSV="$TMPDIR_GATE/pass_b.tsv"
python3 "$PASS_A_PY" < "$FILELIST" > "$A_TSV" 2>"$TMPDIR_GATE/pass_a.err"
PY_RC=$?
node "$PASS_B_JS" < "$FILELIST" > "$B_TSV" 2>"$TMPDIR_GATE/pass_b.err"
ND_RC=$?
if [ "$PY_RC" -ne 0 ] || [ "$ND_RC" -ne 0 ]; then
  echo "[check-description-fidelity] échec d'exécution d'une passe d'extraction (python3 rc=$PY_RC, node rc=$ND_RC)" >&2
  cat "$TMPDIR_GATE/pass_a.err" "$TMPDIR_GATE/pass_b.err" >&2
  exit 3
fi

# Helper : décode une valeur base64 (portable, via node — jamais `base64 -d`/`-D`, dont le
# drapeau diverge entre macOS/BSD et GNU/Linux).
decode_b64() {
  node -e "process.stdout.write(Buffer.from(process.argv[1],'base64').toString('utf8'))" "$1"
}

# Helper : lit le champ $2 (1-indexé) de la ligne dont le chemin ($1) matche, dans le TSV donné.
tsv_field() {
  # $1 = fichier tsv, $2 = chemin recherché, $3 = index de colonne (1-indexé)
  awk -F'\t' -v p="$2" -v idx="$3" '$1==p{print $idx; exit}' "$1"
}

# =====================================================================================
# Bâtisseur de candidats (node) — RÉUTILISE la même fonction d'égalité que le mode audit :
# pour chaque fichier réel, calcule le texte de référence (règle des cas limites : bloc
# replié/littéral -> valeur désérialisée passe A ; scalaire plain -> texte brut passe B, jamais
# la valeur désérialisée qui peut être tronquée ou en échec), construit les DEUX formes
# candidates (guillemets doubles via JSON.stringify — compatible avec l'échappement YAML
# double-guillemet pour du texte sans retour à la ligne — et guillemets simples via doublement
# des apostrophes internes), et écrit des fichiers de VALIDATION synthétiques (frontmatter
# minimal) — jamais le fichier réel, qui reste intact en mode --inventory. La validation
# elle-même est déléguée à une SECONDE passe des mêmes passe A / passe B ci-dessus, sur ces
# fichiers synthétiques : aucune logique de comparaison n'est dupliquée.
# =====================================================================================
INV_BUILD_JS="$TMPDIR_GATE/inv_build.js"
cat > "$INV_BUILD_JS" << 'JSEOF'
const fs = require('fs');
const path = require('path');

function b64(s) { return Buffer.from(s, 'utf8').toString('base64'); }
function db64(s) { return Buffer.from(s, 'base64').toString('utf8'); }

const [, , aTsvPath, bTsvPath, candDir, manifestOut] = process.argv;

function readTsv(p) {
  const map = new Map();
  const lines = fs.readFileSync(p, 'utf8').split('\n');
  for (const line of lines) {
    if (!line) continue;
    const cols = line.split('\t');
    map.set(cols[0], cols);
  }
  return map;
}

const aMap = readTsv(aTsvPath);
const bMap = readTsv(bTsvPath);

fs.mkdirSync(candDir, { recursive: true });

const manifestLines = [];
let idx = 0;
for (const [p, bCols] of bMap) {
  idx += 1;
  const aCols = aMap.get(p);
  const bStatus = bCols[1];
  const bValB64 = bCols[2];
  const style = bCols[3];
  const rawB64 = bCols[4];
  const aStatus = aCols ? aCols[1] : 'ERR';
  const aValB64 = aCols ? aCols[2] : b64('');

  let refText = null;
  let refAvailable = true;
  if (style === 'BLOCK') {
    if (aStatus === 'OK') {
      refText = db64(aValB64);
    } else {
      refAvailable = false;
    }
  } else if (bStatus === 'OK') {
    refText = db64(bValB64);
  } else {
    refAvailable = false;
  }

  let dSynth = '';
  let sSynth = '';
  let candDoubleRawB64 = b64('');
  let candSingleRawB64 = b64('');

  if (refAvailable) {
    const candDoubleRaw = JSON.stringify(refText);
    const candSingleRaw = "'" + refText.replace(/'/g, "''") + "'";
    candDoubleRawB64 = b64(candDoubleRaw);
    candSingleRawB64 = b64(candSingleRaw);
    dSynth = path.join(candDir, `d_${idx}.md`);
    sSynth = path.join(candDir, `s_${idx}.md`);
    fs.writeFileSync(dSynth, `---\ndescription: ${candDoubleRaw}\n---\nbody\n`);
    fs.writeFileSync(sSynth, `---\ndescription: ${candSingleRaw}\n---\nbody\n`);
  }

  const currentRawTrimmedB64 = b64(db64(rawB64).trim());
  manifestLines.push([
    p, style, refAvailable ? '1' : '0', refAvailable ? b64(refText) : b64(''),
    currentRawTrimmedB64, dSynth, sSynth, candDoubleRawB64, candSingleRawB64,
  ].join('\t'));
}

fs.writeFileSync(manifestOut, manifestLines.join('\n') + (manifestLines.length ? '\n' : ''));
process.stdout.write(String(idx));
JSEOF

# =====================================================================================
# Classificateur final (node) — lit le manifeste + les résultats de la seconde passe (sur les
# fichiers synthétiques) + les résultats de la première passe (sur les fichiers réels, pour le
# cas « conservé tel quel ») + la liste d'exceptions, et rend EXACTEMENT une catégorie par
# fichier découvert, dans l'ordre fixe guillemets doubles -> guillemets simples -> forme
# actuelle inchangée -> non convertible.
# =====================================================================================
INV_FINALIZE_JS="$TMPDIR_GATE/inv_finalize.js"
cat > "$INV_FINALIZE_JS" << 'JSEOF'
const fs = require('fs');

function db64(s) { return Buffer.from(s, 'base64').toString('utf8'); }

const [, , manifestPath, synthAPath, synthBPath, realAPath, realBPath, excPath] = process.argv;

function readTsv(p) {
  const map = new Map();
  if (!p || !fs.existsSync(p)) return map;
  const lines = fs.readFileSync(p, 'utf8').split('\n');
  for (const line of lines) {
    if (!line) continue;
    const cols = line.split('\t');
    map.set(cols[0], cols);
  }
  return map;
}

const synthA = readTsv(synthAPath);
const synthB = readTsv(synthBPath);
const realA = readTsv(realAPath);
const realB = readTsv(realBPath);

const exceptions = new Set();
if (excPath && fs.existsSync(excPath)) {
  for (const line of fs.readFileSync(excPath, 'utf8').split('\n')) {
    if (line) exceptions.add(line);
  }
}

function candidateValid(synthPath, refText) {
  if (!synthPath) return false;
  const a = synthA.get(synthPath);
  const b = synthB.get(synthPath);
  if (!a || !b) return false;
  if (a[1] !== 'OK' || b[1] !== 'OK') return false;
  return db64(a[2]) === refText && db64(b[2]) === refText;
}

const manifest = fs.existsSync(manifestPath)
  ? fs.readFileSync(manifestPath, 'utf8').split('\n').filter(Boolean)
  : [];
const counts = {};
const rows = [];
for (const line of manifest) {
  const [p, style, refAvail, refTextB64, currentRawTrimmedB64, dSynth, sSynth, candDoubleB64, candSingleB64] = line.split('\t');
  const refText = refAvail === '1' ? db64(refTextB64) : null;
  const currentRawTrimmed = db64(currentRawTrimmedB64);

  let category;
  let detail;
  let winningRawB64 = '';
  if (exceptions.has(p)) {
    category = 'non_convertible_exception';
    detail = 'exception declaree';
  } else if (refAvail !== '1') {
    category = 'non_convertible';
    detail = 'texte de reference indisponible (bloc replie invalide en YAML strict)';
  } else if (candidateValid(dSynth, refText)) {
    const candDoubleRaw = db64(candDoubleB64);
    category = (style === 'LINE' && currentRawTrimmed === candDoubleRaw) ? 'deja_conforme' : 'a_convertir_double';
    detail = 'guillemets doubles';
    if (category === 'a_convertir_double') winningRawB64 = candDoubleB64;
  } else if (candidateValid(sSynth, refText)) {
    const candSingleRaw = db64(candSingleB64);
    category = (style === 'LINE' && currentRawTrimmed === candSingleRaw) ? 'deja_conforme' : 'a_convertir_simple';
    detail = 'guillemets simples';
    if (category === 'a_convertir_simple') winningRawB64 = candSingleB64;
  } else {
    const ra = realA.get(p);
    const rb = realB.get(p);
    const ok = !!(ra && rb && ra[1] === 'OK' && rb[1] === 'OK' && db64(ra[2]) === db64(rb[2]));
    if (ok) {
      category = 'conserve_tel_quel';
      detail = 'plain deja conforme aux deux regles, non requotable sans perte';
    } else {
      category = 'non_convertible';
      detail = 'aucune forme candidate (double/simple) ni la forme actuelle ne satisfait les deux regles';
    }
  }
  counts[category] = (counts[category] || 0) + 1;
  rows.push(`${p}\t${category}\t${detail}\t${winningRawB64}`);
}

process.stdout.write(rows.join('\n') + (rows.length ? '\n' : ''));
process.stderr.write(`[inventory-counts] ${JSON.stringify(counts)}\n`);
JSEOF

run_inventory() {
  # $1 = répertoire de sortie pour la classification (TMPDIR_GATE par défaut)
  local out_dir="$1"
  local cand_dir="$out_dir/cand"
  local manifest="$out_dir/manifest.tsv"
  node "$INV_BUILD_JS" "$A_TSV" "$B_TSV" "$cand_dir" "$manifest" > "$out_dir/inv_build.count"

  local synth_list="$out_dir/synth_files.txt"
  awk -F'\t' '{if ($6!="") print $6; if ($7!="") print $7}' "$manifest" > "$synth_list"

  local synth_a="$out_dir/synth_a.tsv"
  local synth_b="$out_dir/synth_b.tsv"
  if [ -s "$synth_list" ]; then
    python3 "$PASS_A_PY" < "$synth_list" > "$synth_a" 2>"$out_dir/synth_a.err"
    node "$PASS_B_JS" < "$synth_list" > "$synth_b" 2>"$out_dir/synth_b.err"
  else
    : > "$synth_a"
    : > "$synth_b"
  fi

  local exc_abs="$out_dir/exceptions_abs_inv.txt"
  : > "$exc_abs"
  local n_exc="${#EXCEPTIONS_REL[@]}"
  local i=0
  while [ "$i" -lt "$n_exc" ]; do
    printf '%s\n' "$ROOT/${EXCEPTIONS_REL[$i]}" >> "$exc_abs"
    i=$((i + 1))
  done

  node "$INV_FINALIZE_JS" "$manifest" "$synth_a" "$synth_b" "$A_TSV" "$B_TSV" "$exc_abs"
}

if [ "$MODE" = "inventory" ]; then
  CLASSIFICATION="$(run_inventory "$TMPDIR_GATE")"
  DBL=0; SGL=0; SAME=0; CONS=0; NONC=0
  while IFS=$'\t' read -r p cat detail _winraw; do
    [ -n "$p" ] || continue
    case "$cat" in
      a_convertir_double) DBL=$((DBL + 1)); label="à convertir en guillemets doubles" ;;
      a_convertir_simple) SGL=$((SGL + 1)); label="à convertir en guillemets simples" ;;
      deja_conforme) SAME=$((SAME + 1)); label="déjà conforme" ;;
      conserve_tel_quel) CONS=$((CONS + 1)); label="conservé tel quel" ;;
      non_convertible|non_convertible_exception) NONC=$((NONC + 1)); label="non convertible" ;;
      *) label="$cat" ;;
    esac
    echo "$p	$label	$detail"
  done <<< "$CLASSIFICATION"
  echo "[check-description-fidelity] inventaire — $FILE_COUNT découvert(s) : ${DBL} à convertir (guillemets doubles), ${SGL} à convertir (guillemets simples), ${SAME} déjà conforme(s), ${CONS} conservé(s) tel quel, ${NONC} non convertible(s)"
  exit 0
fi

# =====================================================================================
# Mode --fix — RÉUTILISE la classification de --inventory (MÊME fonction d'égalité, aucune
# seconde implémentation). Pour chaque fichier « à convertir » : construit la forme complète
# du fichier réel avec la description remplacée (span exact : une ligne pour plain/quoté, la
# clé + toutes les lignes de continuation plus indentées pour un scalaire replié/littéral),
# la STAGE dans un fichier temporaire (jamais une écriture directe), VALIDE la forme stagée par
# les deux passes AVANT toute écriture réelle — un seul échec ABANDONNE tout le lot, aucune
# écriture n'a lieu (jamais une conversion partielle silencieuse) — puis, seulement si TOUT
# valide, commit (copie) sur les fichiers réels, et RELIT chaque fichier réellement posé pour
# revalider sur le contenu tel qu'il est désormais sur disque (pas seulement sur la forme
# stagée avant écriture).
# =====================================================================================
if [ "$MODE" = "fix" ]; then
  CLASSIFICATION="$(run_inventory "$TMPDIR_GATE")"

  APPLY_SPAN_JS="$TMPDIR_GATE/apply_span.js"
  cat > "$APPLY_SPAN_JS" << 'JSEOF'
// apply_span.js <inputPath> <outputPath> <newDescriptionLine>
// Localise la clé description: en tête de frontmatter (colonne 0), détermine son span exact
// (une ligne pour plain/quoté ; la ligne de clé + toutes les lignes de continuation plus
// indentées pour un scalaire replié/littéral) et remplace CE span par newDescriptionLine dans
// une COPIE écrite à outputPath — jamais une écriture directe de inputPath.
const fs = require('fs');

const [, , inputPath, outputPath, newLine] = process.argv;
const content = fs.readFileSync(inputPath, 'utf8');
const lines = content.split('\n');
if (lines[0].trim() !== '---') {
  console.error('no frontmatter');
  process.exit(1);
}
let closeIdx = -1;
for (let i = 1; i < lines.length; i++) {
  if (lines[i].trim() === '---') { closeIdx = i; break; }
}
if (closeIdx === -1) {
  console.error('no closing ---');
  process.exit(1);
}
let descIdx = -1;
for (let i = 1; i < closeIdx; i++) {
  if (/^description:/.test(lines[i])) { descIdx = i; break; }
}
if (descIdx === -1) {
  console.error('no description line');
  process.exit(1);
}
const afterColon = lines[descIdx].slice('description:'.length).trim();
const isBlock = afterColon.startsWith('>') || afterColon.startsWith('|');
let spanEnd = descIdx;
if (isBlock) {
  let j = descIdx + 1;
  while (j < closeIdx) {
    const l = lines[j];
    if (l.trim() === '') { j += 1; continue; }
    if (/^[ \t]/.test(l)) { spanEnd = j; j += 1; continue; }
    break;
  }
}
const before = lines.slice(0, descIdx);
const after = lines.slice(spanEnd + 1);
const result = [...before, newLine, ...after].join('\n');
fs.writeFileSync(outputPath, result);
JSEOF

  FIX_STAGE_DIR="$TMPDIR_GATE/fix_stage"
  mkdir -p "$FIX_STAGE_DIR"
  FIX_MANIFEST="$TMPDIR_GATE/fix_manifest.txt"
  : > "$FIX_MANIFEST"
  IDX=0
  CONVERT_DBL=0
  CONVERT_SGL=0
  BUILD_ERR=0
  while IFS=$'\t' read -r p cat detail winraw; do
    [ -n "$p" ] || continue
    case "$cat" in
      a_convertir_double|a_convertir_simple) ;;
      *) continue ;;
    esac
    IDX=$((IDX + 1))
    NEWTEXT="$(decode_b64 "$winraw")"
    STAGED="$FIX_STAGE_DIR/f_$IDX.md"
    if ! node "$APPLY_SPAN_JS" "$p" "$STAGED" "description: $NEWTEXT" 2>"$TMPDIR_GATE/fix_apply_$IDX.err"; then
      echo "[check-description-fidelity] ✗ --fix : échec de construction du span pour $p : $(cat "$TMPDIR_GATE/fix_apply_$IDX.err")" >&2
      BUILD_ERR=1
      continue
    fi
    printf '%s\t%s\n' "$p" "$STAGED" >> "$FIX_MANIFEST"
    if [ "$cat" = "a_convertir_double" ]; then CONVERT_DBL=$((CONVERT_DBL + 1)); else CONVERT_SGL=$((CONVERT_SGL + 1)); fi
  done <<< "$CLASSIFICATION"

  if [ "$BUILD_ERR" -eq 1 ]; then
    echo "[check-description-fidelity] ✗ --fix ABANDONNÉ — construction du span en échec sur au moins un fichier ; AUCUNE écriture appliquée" >&2
    exit 1
  fi

  # --- Validation AVANT écriture, sur les formes stagées (jamais directement sur les fichiers réels). ---
  STAGE_LIST="$TMPDIR_GATE/fix_stage_list.txt"
  cut -f2 "$FIX_MANIFEST" > "$STAGE_LIST"
  STAGE_A="$TMPDIR_GATE/fix_stage_a.tsv"
  STAGE_B="$TMPDIR_GATE/fix_stage_b.tsv"
  if [ -s "$STAGE_LIST" ]; then
    python3 "$PASS_A_PY" < "$STAGE_LIST" > "$STAGE_A" 2>"$TMPDIR_GATE/fix_stage_a.err"
    node "$PASS_B_JS" < "$STAGE_LIST" > "$STAGE_B" 2>"$TMPDIR_GATE/fix_stage_b.err"
  else
    : > "$STAGE_A"
    : > "$STAGE_B"
  fi

  FIX_BAD=0
  while IFS=$'\t' read -r realp stagedp; do
    [ -n "$realp" ] || continue
    sa_status="$(tsv_field "$STAGE_A" "$stagedp" 2)"
    sa_val="$(tsv_field "$STAGE_A" "$stagedp" 3)"
    sb_status="$(tsv_field "$STAGE_B" "$stagedp" 2)"
    sb_val="$(tsv_field "$STAGE_B" "$stagedp" 3)"
    if [ "$sa_status" != "OK" ] || [ "$sb_status" != "OK" ] || [ "$sa_val" != "$sb_val" ]; then
      echo "[check-description-fidelity] ✗ --fix : la forme construite pour $realp NE satisfait PAS les deux règles avant écriture (A=$sa_status B=$sb_status) — fichier NON écrit" >&2
      FIX_BAD=1
    fi
  done < "$FIX_MANIFEST"

  if [ "$FIX_BAD" -eq 1 ]; then
    echo "[check-description-fidelity] ✗ --fix ABANDONNÉ — au moins une forme construite ne valide pas avant écriture ; AUCUNE écriture appliquée" >&2
    exit 1
  fi

  # --- Tout valide : commit réel (copie du contenu validé sur chaque fichier réel). ---
  while IFS=$'\t' read -r realp stagedp; do
    [ -n "$realp" ] || continue
    cp "$stagedp" "$realp"
  done < "$FIX_MANIFEST"

  # --- Post-écriture : RELIT chaque fichier réellement posé et revalide sur le contenu tel
  # qu'il est désormais sur disque — pas seulement sur la forme stagée avant écriture. ---
  REAL_CONVERTED_LIST="$TMPDIR_GATE/fix_real_converted.txt"
  cut -f1 "$FIX_MANIFEST" > "$REAL_CONVERTED_LIST"
  POSTCHECK_BAD=0
  if [ -s "$REAL_CONVERTED_LIST" ]; then
    POST_A="$TMPDIR_GATE/fix_post_a.tsv"
    POST_B="$TMPDIR_GATE/fix_post_b.tsv"
    python3 "$PASS_A_PY" < "$REAL_CONVERTED_LIST" > "$POST_A" 2>"$TMPDIR_GATE/fix_post_a.err"
    node "$PASS_B_JS" < "$REAL_CONVERTED_LIST" > "$POST_B" 2>"$TMPDIR_GATE/fix_post_b.err"
    while IFS= read -r realp; do
      [ -n "$realp" ] || continue
      pa_status="$(tsv_field "$POST_A" "$realp" 2)"
      pa_val="$(tsv_field "$POST_A" "$realp" 3)"
      pb_status="$(tsv_field "$POST_B" "$realp" 2)"
      pb_val="$(tsv_field "$POST_B" "$realp" 3)"
      if [ "$pa_status" != "OK" ] || [ "$pb_status" != "OK" ] || [ "$pa_val" != "$pb_val" ]; then
        echo "[check-description-fidelity] ✗ --fix : le fichier réellement posé $realp NE satisfait PLUS les deux règles après écriture (A=$pa_status B=$pb_status) — INCOHÉRENCE, à investiguer manuellement" >&2
        POSTCHECK_BAD=1
      fi
    done < "$REAL_CONVERTED_LIST"
  fi

  if [ "$POSTCHECK_BAD" -eq 1 ]; then
    echo "[check-description-fidelity] ✗ --fix : incohérence post-écriture détectée (voir ci-dessus) — fichiers déjà écrits, divergence à la relecture" >&2
    exit 1
  fi

  echo "[check-description-fidelity] --fix : $IDX fichier(s) converti(s) (${CONVERT_DBL} guillemets doubles, ${CONVERT_SGL} guillemets simples), validés AVANT ET APRÈS écriture"
  exit 0
fi

# =====================================================================================
# Mode AUDIT (défaut) — rapprochement par comm sur listes triées, jamais par un compte de lignes.
# =====================================================================================
A_FP="$TMPDIR_GATE/a_fp.tsv"
B_FP="$TMPDIR_GATE/b_fp.tsv"
awk -F'\t' 'BEGIN{OFS="\t"}{print $1, $2":"$3}' "$A_TSV" | LC_ALL=C sort > "$A_FP"
awk -F'\t' 'BEGIN{OFS="\t"}{print $1, $2":"$3}' "$B_TSV" | LC_ALL=C sort > "$B_FP"

ONLY_A="$TMPDIR_GATE/only_a.tsv"
ONLY_B="$TMPDIR_GATE/only_b.tsv"
comm -23 "$A_FP" "$B_FP" > "$ONLY_A"
comm -13 "$A_FP" "$B_FP" > "$ONLY_B"

ALL_VIOLATIONS="$TMPDIR_GATE/all_violations.txt"
{ cut -f1 "$ONLY_A"; cut -f1 "$ONLY_B"; } | LC_ALL=C sort -u > "$ALL_VIOLATIONS"

# --- Chemins absolus des exceptions (relatifs à ROOT) ---
EXC_ABS_FILE="$TMPDIR_GATE/exceptions_abs.txt"
: > "$EXC_ABS_FILE"
N_EXC="${#EXCEPTIONS_REL[@]}"
i=0
while [ "$i" -lt "$N_EXC" ]; do
  printf '%s\n' "$ROOT/${EXCEPTIONS_REL[$i]}" >> "$EXC_ABS_FILE"
  i=$((i + 1))
done
LC_ALL=C sort -o "$EXC_ABS_FILE" "$EXC_ABS_FILE"

REAL_VIOLATIONS="$TMPDIR_GATE/real_violations.txt"
comm -23 "$ALL_VIOLATIONS" "$EXC_ABS_FILE" > "$REAL_VIOLATIONS"
REAL_VIOLATIONS_COUNT=$(wc -l < "$REAL_VIOLATIONS" | tr -d ' ')

# --- Cliquet des exceptions : existence + non-péremption ---
EXC_FAIL=0
i=0
while [ "$i" -lt "$N_EXC" ]; do
  rel="${EXCEPTIONS_REL[$i]}"
  reason="${EXCEPTIONS_REASON[$i]}"
  abs="$ROOT/$rel"
  if [ ! -f "$abs" ]; then
    echo "[check-description-fidelity] ✗ exception orpheline : $rel (fichier absent) — $reason" >&2
    EXC_FAIL=1
  else
    a_status="$(tsv_field "$A_TSV" "$abs" 2)"
    a_val="$(tsv_field "$A_TSV" "$abs" 3)"
    b_status="$(tsv_field "$B_TSV" "$abs" 2)"
    b_val="$(tsv_field "$B_TSV" "$abs" 3)"
    if [ -n "$a_status" ] && [ "$a_status" = "OK" ] && [ "$b_status" = "OK" ] && [ "$a_val" = "$b_val" ]; then
      echo "[check-description-fidelity] ✗ exception périmée : $rel satisferait désormais les deux règles — retirer cette exception" >&2
      EXC_FAIL=1
    fi
    echo "[check-description-fidelity] exception : $rel — $reason"
  fi
  i=$((i + 1))
done

if [ "$REAL_VIOLATIONS_COUNT" -eq 0 ] && [ "$EXC_FAIL" -eq 0 ]; then
  echo "[check-description-fidelity] PASS — $FILE_COUNT fichier(s) analysé(s), 0 violation, ${N_EXC} exception(s) déclarée(s)"
  exit 0
fi

echo "[check-description-fidelity] FAIL — $REAL_VIOLATIONS_COUNT violation(s) sur $FILE_COUNT fichier(s) analysé(s)" >&2
while IFS= read -r path; do
  [ -n "$path" ] || continue
  a_status="$(tsv_field "$A_TSV" "$path" 2)"
  a_val_b64="$(tsv_field "$A_TSV" "$path" 3)"
  b_status="$(tsv_field "$B_TSV" "$path" 2)"
  b_val_b64="$(tsv_field "$B_TSV" "$path" 3)"
  if [ "$a_status" != "OK" ]; then
    a_msg="$(decode_b64 "$a_val_b64")"
    echo "  [$path] passe A ÉCHOUE (YAML strict) : $a_msg" >&2
  else
    a_val="$(decode_b64 "$a_val_b64")"
    b_val="$(decode_b64 "$b_val_b64")"
    a_trunc=$(printf '%s' "$a_val" | cut -c1-120)
    b_trunc=$(printf '%s' "$b_val" | cut -c1-120)
    echo "  [$path] divergence : attendu(A)=\"${a_trunc}\" obtenu(B)=\"${b_trunc}\"" >&2
  fi
done < "$REAL_VIOLATIONS"

exit 1
