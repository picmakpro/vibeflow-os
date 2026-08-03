#!/usr/bin/env bash
# check-gsd-config.sh — Le .planning/config.json de ce lab est-il aligné sur le moteur GSD installé ?
#
# Rôle (ADR-055 §3) : répondre au FAIT, jamais au métier. Ce script ne dit JAMAIS qu'une clé est
# « mauvaise », ni qu'un toggle est mal réglé — seulement que le moteur installé NE CONNAÎT PAS
# telle clé, et que tel toggle de cycle N'EST PAS ÉCRIT dans le fichier audité. C'est le jugement
# de l'agent (ou de l'utilisateur) de décider quoi en faire.
#
# Deux faits constatés, indépendants, cumulables dans un même appel :
#
#   (a) CLÉS INCONNUES — des clés présentes dans le fichier audité que le moteur ignorera.
#   (b) TOGGLES DE CYCLE AU DÉFAUT IMPLICITE — des toggles que la Phase 23 arbitre et que ce lab
#       laisse tomber au défaut amont au lieu de les écrire (piloter ses étages par omission).
#
# --- Source des clés connues : LUE DEPUIS LE MOTEUR, jamais en dur ------------------------------
# Les clés connues sont lues à l'exécution depuis le gsd-core installé, donc ce gate NE PÉRIME PAS
# quand le moteur monte de version. L'union de TROIS sources est nécessaire — chacune seule produit
# des faux positifs (fait vérifié, pas supposé) :
#
#   1. VALID_CONFIG_KEYS  (bin/lib/config.cjs)             — Set de clés pointées (104 aujourd'hui).
#   2. configKeys         (bin/lib/capability-registry.cjs) — clés de config déclarées par les
#      capabilities (58 aujourd'hui). Indispensable : workflow.code_review, workflow.pattern_mapper
#      et workflow.ui_review sont ABSENTS de VALID_CONFIG_KEYS et ne vivent QUE là — un gate qui ne
#      lirait que la source 1 signalerait à tort trois clés parfaitement légitimes.
#   3. CONFIG_DEFAULTS    (bin/lib/configuration.cjs)      — les défauts canoniques imbriqués. Même
#      raison, symétrique : workflow._auto_chain_active (écrit par le moteur lui-même quand une
#      chaîne --auto est active) n'est dans AUCUNE des deux premières sources. Sans cette troisième
#      source, le gate signalerait comme « inconnue » une clé que le moteur écrit de sa propre main.
#      C'est aussi la source qui donne la VALEUR du défaut amont d'un toggle (volet b).
#
# Inversement workflow.node_repair et workflow.node_repair_budget ne vivent que dans la source 1.
# Les trois sources sont donc lues et unies ; aucune n'est suffisante seule.
#
# UNE EXCEPTION, ASSUMÉE ET NOMMÉE : la liste engineExtra (voir plus bas) recopie en dur une poignée
# de littéraux de premier niveau que le moteur ajoute à son propre KNOWN_TOP_LEVEL sans les exporter
# nulle part (config-loader.cjs) — aucun module de bin/lib ne les expose, ils ne sont donc pas
# lisibles dynamiquement. C'est le SEUL endroit du script où des noms de clés sont écrits à la main,
# et c'est le seul point par lequel le gate peut dériver à la montée de version du moteur. Le cas 26
# de la suite dédiée exerce ce mirroir contre le moteur réel, précisément pour qu'une telle dérive
# se voie en test rouge au lieu de passer en silence.
#
# --- LIMITES DE PORTÉE CONNUES — LES DEUX SENS SONT ATTEIGNABLES -------------------------------
# Ce gate n'est PAS en parité avec le moteur sur l'ensemble des clés de premier niveau. Il peut se
# tromper dans les DEUX sens, et c'est mesuré, pas supposé :
#
#   (i) FAUX POSITIF possible (schéma fédéré) — le moteur complète son KNOWN_TOP_LEVEL avec un
#       overlay FÉDÉRÉ résolu pour le lab audité (clés déclarées par des capabilities tierces
#       installées dans ce lab). Ce gate ne lit PAS cet overlay : sur un lab qui en installerait,
#       il peut signaler comme inconnue une clé que le moteur, lui, accepterait.
#
#   (ii) FAUX NÉGATIF possible (sur-ensemble statique) — et c'est le sens que la version initiale
#       de cet en-tête déclarait à tort impossible. Le moteur bâtit son KNOWN_TOP_LEVEL
#       (config-loader.cjs) à partir de VALID_CONFIG_KEYS + DYNAMIC_KEY_PATTERNS + les littéraux
#       en dur — NI configKeys, NI CONFIG_DEFAULTS. Le KNOWN_TOP de ce script, lui, dérive de
#       l'union des TROIS sources : il est donc un SUR-ENSEMBLE strict de celui du moteur. Toute
#       clé de premier niveau présente dans les sources 2 ou 3 mais absente de la source 1 est
#       épargnée ici et signalée là-bas.
#       Mesuré contre le moteur installé le 2026-08-03 : le script connaît en plus _comment,
#       claude_orchestration, external_job, intel, mempalace, profile-pipeline (6 clés) ; le
#       moteur ne connaît rien que le script ignore. Cas reproduit de bout en bout : sur un lab
#       par ailleurs aligné portant _comment (une CHAÎNE de documentation de CONFIG_DEFAULTS,
#       jamais une clé de config), ce gate sort en 3 « rien à signaler » pendant que loadConfig
#       avertit « unknown config key(s): _comment ».
#       Conséquence de second ordre : un bloc de ce type est traité comme conteneur CONNU, donc
#       ses sous-clés sont signalées à sa place — le conseil rendu porte alors sur la mauvaise
#       cible.
#
# La ligne « reproduit ce comportement à l'identique » plus bas vaut pour la MÉCANIQUE (comparer
# les clés de premier niveau à un ensemble connu), pas pour la COMPOSITION de cet ensemble.
#
# Le gate reste advisory et ne bloque rien. La DIRECTION du correctif (mettre KNOWN_TOP en parité
# stricte avec le moteur — ce qui rouvre des faux positifs sur les labs fédérés — ou lire aussi
# l'overlay fédéré en 4ᵉ source) est volontairement NON tranchée ici : hors périmètre du plan
# 23-02, dont la recherche amont ne mentionne pas la source fédérée. Escaladée, à instruire avant
# d'élargir la portée du gate.
#
# --- Granularité de comparaison (choix explicite, pas un accident) ------------------------------
# Le moteur ne valide QUE le premier niveau : son KNOWN_TOP_LEVEL est l'ensemble des premiers
# segments des clés connues, plus les topLevel de DYNAMIC_KEY_PATTERNS, plus une poignée de
# littéraux ; il signale ensuite les clés de premier niveau du fichier qui n'y sont pas. C'est
# pourquoi il nomme « gates, safety » et jamais leurs dix sous-clés. Ce script reproduit la même
# MÉCANIQUE pour le premier niveau (son ensemble connu n'est PAS le même — voir « LIMITES DE
# PORTÉE » ci-dessus), puis va UN CRAN PLUS LOIN, en le bornant :
#
#   - clé de PREMIER NIVEAU inconnue  → signalée EN TANT QUE BLOC (son nom seul, pas ses sous-clés) ;
#   - sous-clé inconnue sous un conteneur connu → signalée par son chemin pointé complet, MAIS
#     seulement si ce conteneur déclare au moins un enfant dans les clés connues. Un conteneur
#     déclaré « nu » (aucun enfant connu — parallelization, agent_skills…) est OPAQUE pour le
#     moteur, qui en consomme la valeur entière : y signaler des sous-clés serait inventer un fait.
#
# --- Trois états par toggle (volet b) — et surtout PAS deux ------------------------------------
#   1. écrit dans le fichier audité                      → rien à signaler ;
#   2. absent du fichier, présent dans les défauts amont → signalé « au défaut amont », avec la
#      valeur effective LUE dans le moteur (jamais recopiée ici) ;
#   3. absent du fichier ET absent des défauts amont     → signalé « sans défaut lisible dans le
#      moteur », SANS aucune valeur ET SANS CAUSE. Le script observe une absence, jamais sa raison :
#      énoncer « résolu par la capability elle-même » serait fabriquer un fait, et serait faux pour
#      node_repair / node_repair_budget, qui ne sont pas des capabilities (voir plus haut). Cas de
#      workflow.ui_review : il est référencé comme condition
#      d'activation par le registre de capabilities mais n'a de valeur par défaut nulle part. Une
#      valeur qui n'existe nulle part N'EST PAS `false` — elle est ABSENTE. L'afficher comme faux
#      serait fabriquer un fait, précisément ce qu'ADR-055 §3 interdit à un script.
#
# --- Sécurité (T-23-02-01, §Security Domain du RESEARCH) ---------------------------------------
# Le fichier audité est une entrée NON MAÎTRISÉE (ce gate est fait pour tourner sur n'importe quel
# lab) : ses clés comme ses valeurs sont hostiles par hypothèse. Aucun contenu lu depuis ce fichier
# n'est jamais interpolé dans une commande shell. L'aplatissement du JSON se fait entièrement côté
# node, et les jetons remontés à bash sont encodés en JSON (JSON.stringify) : ils ne peuvent donc
# contenir ni tabulation, ni saut de ligne, ni guillemet nu, et un octet de contrôle ressort en
# échappement \uXXXX plutôt qu'en octet brut dans la sortie de session. Les chemins sont passés à
# node par l'ENVIRONNEMENT, jamais par concaténation dans le texte du programme.
#
# Usage:
#   check-gsd-config.sh [--path <dir>] [--hook] [--quiet]
# Defaults: --path .
#
# Surcharges d'environnement (patron VF_ du dépôt, ADR-054) :
#   VF_CONFIG_PATH    chemin complet du config.json audité (défaut <path>/.planning/config.json)
#   VF_GSD_CORE_LIB   dossier bin/lib du moteur. S'il est défini, il REMPLACE la cascade au lieu de
#                     s'y ajouter — sans quoi aucune fixture ne pourrait simuler un moteur absent,
#                     la cascade retombant toujours sur le moteur réel du poste.
#
# Cascade de résolution du moteur (le lab courant PRIME, même priorité que la cascade $S de
# mission-flow.md) : <path>/.claude/gsd-core/bin/lib, puis
# <path>/node_modules/@opengsd/gsd-core/bin/lib, puis $HOME/.claude/gsd-core/bin/lib.
#
# --hook change UNIQUEMENT le format d'affichage (parité d'interface avec les trois autres gates du
# module) ; ce script n'a qu'un seul gabarit de signal, donc --hook n'altère aucun rendu — il ne
# sert qu'à la cohérence d'interface et au gate de mutuelle exclusion avec --quiet. Les 3 exits
# (0/3/64) restent identiques avec ou sans --hook.
#
# Interdit dans ce script (critère machine du plan) : aucun appel à eval, aucun bash -c sur une
# valeur lue depuis le fichier audité ou depuis la sortie node.
#
# Exit codes:
#   0  = au moins un signal [gsd-config] émis
#   3  = rien à signaler (fichier absent, JSON illisible, moteur introuvable, ou lab aligné)
#   64 = argument inconnu, --path sans valeur (ou valeur vide), ou --hook + --quiet ensemble
#
# CONTRAT FERMÉ : {0, 3, 64} et RIEN D'AUTRE. Aucun chemin d'échec ne doit en sortir — HOME non
# défini inclus (référence guardée `${HOME:-}` dans la cascade : sous set -u une référence nue y
# sortait en 1 avec un message sur stderr MALGRÉ --quiet). La suite dédiée porte un balayage final
# qui rejoue toutes les fixtures et échoue sur tout rc hors de cet ensemble.
set -uo pipefail

ROOT="."
HOOK=0
QUIET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      # La valeur VIDE est refusée au même titre que l'absence de valeur : `--path ""` passerait
      # le seul test de comptage et déplacerait silencieusement la cible sur /.planning/config.json.
      # (Le court-circuit de `||` garantit que "$2" n'est évalué que s'il existe, sous set -u.)
      if [ "$#" -lt 2 ] || [ -z "$2" ]; then
        echo "[check-gsd-config] --path nécessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    --hook) HOOK=1; shift ;;
    --quiet) QUIET=1; shift ;;
    # --help rend le BLOC D'EN-TÊTE et lui seul : la lecture s'arrête à la première ligne non
    # commentée du fichier. Un `grep '^# '` sur tout le fichier ramasserait aussi les commentaires
    # d'implémentation et écraserait la mise en page de l'aide.
    -h|--help) awk 'NR==1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0"; exit 0 ;;
    *) echo "[check-gsd-config] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

# Gate de mutuelle exclusion, avant toute autre logique (même position que dans l'analogue).
if [ "$HOOK" -eq 1 ] && [ "$QUIET" -eq 1 ]; then
  echo "[check-gsd-config] --hook et --quiet sont mutuellement exclusifs" >&2
  exit 64
fi

say() { [ "$QUIET" -eq 1 ] || echo "[check-gsd-config] $*" >&2; }

# --- Fichier audité -----------------------------------------------------------------------------
CONFIG_PATH="${VF_CONFIG_PATH:-$ROOT/.planning/config.json}"

if [ ! -f "$CONFIG_PATH" ]; then
  say "$CONFIG_PATH introuvable — rien à constater."
  exit 3
fi

# --- Résolution du moteur -----------------------------------------------------------------------
# VF_GSD_CORE_LIB, s'il est défini, remplace la cascade (voir en-tête).
LIB=""
if [ -n "${VF_GSD_CORE_LIB:-}" ]; then
  [ -f "$VF_GSD_CORE_LIB/config.cjs" ] && LIB="$VF_GSD_CORE_LIB"
else
  for candidate in \
    "$ROOT/.claude/gsd-core/bin/lib" \
    "$ROOT/node_modules/@opengsd/gsd-core/bin/lib" \
    "${HOME:-}/.claude/gsd-core/bin/lib"
  do
    if [ -f "$candidate/config.cjs" ]; then LIB="$candidate"; break; fi
  done
fi

if [ -z "$LIB" ]; then
  say "moteur gsd-core introuvable — un gate qui ne peut rien constater ne prétend rien."
  exit 3
fi

if ! command -v node >/dev/null 2>&1; then
  say "node introuvable — rien à constater."
  exit 3
fi

# --- Liste arbitrée des toggles de cycle (D-19) -------------------------------------------------
# CHOIX DE DOCTRINE, volontairement COURT et NON dérivé du registre : ce sont les cinq toggles que
# la Phase 23 arbitre réellement. Inventorier les 44 capabilities du moteur est explicitement
# écarté par D-19 (candidat Phase 24) — un gate qui réclamerait l'écriture des 58 clés de
# capability transformerait un signal utile en bruit permanent.
ARBITRATED_TOGGLES="workflow.code_review workflow.pattern_mapper workflow.node_repair workflow.node_repair_budget workflow.ui_review"

# --- Extraction des faits (côté node : aucune interpolation shell de contenu de fichier) --------
# Portabilité (ADR-054, bash 3.2 macOS) : le programme est chargé par `read -r -d ''` et SURTOUT
# PAS par `NODE_PROG=$(cat <<'NODEJS' … )`. bash 3.2 scanne le corps d'un here-doc imbriqué dans une
# substitution de commande à la recherche de quotes : la moindre apostrophe française dans un
# commentaire JS (« l'exporte », « d'un ») y ouvre une chaîne fantôme et casse le script entier avec
# une erreur de syntaxe pointant des dizaines de lignes plus bas. Vérifié sur bash 3.2.57.
IFS= read -r -d '' NODE_PROG <<'NODEJS' || true
const fs = require('fs');
const path = require('path');
const LIB = process.env.VF_LIB || '';
const CFG = process.env.VF_CFG || '';
const ARB = (process.env.VF_ARB || '').split(/\s+/).filter(Boolean);

function tryReq(f) { try { return require(path.join(LIB, f)); } catch (e) { return null; } }

const mConfig = tryReq('config.cjs');
const mConfiguration = tryReq('configuration.cjs');
const mRegistry = tryReq('capability-registry.cjs');

// Source 1 — VALID_CONFIG_KEYS (repli sur configuration.cjs, qui l'exporte aussi).
let VALID = (mConfig && mConfig.VALID_CONFIG_KEYS) || (mConfiguration && mConfiguration.VALID_CONFIG_KEYS) || null;
let validArr = [];
try { validArr = VALID ? Array.from(VALID) : []; } catch (e) { validArr = []; }
// Aucune clé connue lisible => le gate ne peut rien constater, il ne prétend rien.
if (validArr.length === 0) process.exit(3);

// Source 2 — configKeys du registre de capabilities.
const ck = (mRegistry && mRegistry.configKeys && typeof mRegistry.configKeys === 'object') ? Object.keys(mRegistry.configKeys) : [];

// Source 3 — CONFIG_DEFAULTS canoniques (donne aussi la VALEUR des défauts amont).
const DEFAULTS = (mConfiguration && mConfiguration.CONFIG_DEFAULTS && typeof mConfiguration.CONFIG_DEFAULTS === 'object') ? mConfiguration.CONFIG_DEFAULTS : {};
const dynTop = (mConfiguration && Array.isArray(mConfiguration.DYNAMIC_KEY_PATTERNS))
  ? mConfiguration.DYNAMIC_KEY_PATTERNS.map(p => p && p.topLevel).filter(x => typeof x === 'string')
  : [];

function flatten(o, prefix, out, withContainers) {
  for (const k of Object.keys(o)) {
    const v = o[k];
    const kp = prefix ? prefix + '.' + k : k;
    const isObj = v && typeof v === 'object' && !Array.isArray(v);
    if (isObj) { if (withContainers) out.push(kp); flatten(v, kp, out, withContainers); }
    else out.push(kp);
  }
  return out;
}

const KNOWN = new Set([].concat(validArr, ck, flatten(DEFAULTS, '', [], true)));

// Miroir exact du KNOWN_TOP_LEVEL du moteur (config-loader.cjs) : premiers segments des clés
// connues + topLevel des motifs dynamiques + les littéraux que le moteur ajoute en dur.
//
// engineExtra est la SEULE liste écrite à la main de ce script (exception nommée en en-tête) : ces
// littéraux ne sont exportés par aucun module de bin/lib, donc pas lisibles dynamiquement. Plusieurs
// d'entre eux (depth, multiRepo, branching_strategy, research en premier niveau) n'existent dans
// AUCUNE des trois sources dynamiques : les retirer parce qu'ils « semblent redondants » rouvrirait
// un faux positif. La redondance apparente des autres est délibérément CONSERVÉE — la couverture par
// les sources dynamiques dépend de la version du moteur, et un mirroir fidèle reste juste même si
// une version future retire l'une de ces clés de ses listes exportées.
const engineExtra = ['model_overrides', 'context_window', 'resolve_model_ids', 'claude_md_path',
  'effort', 'fast_mode', 'depth', 'multiRepo', 'branching_strategy', 'research'];
const KNOWN_TOP = new Set([].concat(
  Array.from(KNOWN).map(k => k.split('.')[0]), dynTop, engineExtra));

// Conteneurs qui déclarent au moins un enfant connu (les autres sont opaques — voir en-tête).
const hasChildren = new Set();
for (const k of KNOWN) { const i = k.indexOf('.'); if (i > 0) hasChildren.add(k.slice(0, i)); }

let cfg;
try { cfg = JSON.parse(fs.readFileSync(CFG, 'utf8')); } catch (e) { process.exit(3); }
if (!cfg || typeof cfg !== 'object' || Array.isArray(cfg)) process.exit(3);

// Jetons encodés en JSON : ni tabulation, ni saut de ligne, ni octet de contrôle brut ne peuvent
// franchir la frontière vers bash (T-23-02-01).
const J = s => JSON.stringify(String(s));
const out = [];

for (const k of Object.keys(cfg)) {
  if (!KNOWN_TOP.has(k)) out.push('UNKNOWN_BLOCK\t' + J(k));
}

for (const k of Object.keys(cfg)) {
  if (!KNOWN_TOP.has(k)) continue;   // déjà signalé en tant que bloc
  if (!hasChildren.has(k)) continue; // conteneur opaque pour le moteur
  const v = cfg[k];
  if (!v || typeof v !== 'object' || Array.isArray(v)) continue;
  for (const leaf of flatten(v, k, [], false)) {
    if (!KNOWN.has(leaf)) out.push('UNKNOWN_KEY\t' + J(leaf));
  }
}

function lookup(o, dotted) {
  let cur = o;
  for (const p of dotted.split('.')) {
    if (cur && typeof cur === 'object' && Object.prototype.hasOwnProperty.call(cur, p)) cur = cur[p];
    else return { found: false };
  }
  return { found: true, value: cur };
}

for (const t of ARB) {
  if (lookup(cfg, t).found) continue;           // état 1 : écrit → rien à signaler
  const up = lookup(DEFAULTS, t);
  if (up.found) out.push('TOGGLE_DEFAULT\t' + J(t) + '\t' + J(up.value));  // état 2
  else out.push('TOGGLE_ABSENT\t' + J(t));                                  // état 3 : sans valeur
}

process.stdout.write(out.map(l => l + '\n').join(''));
NODEJS

RAW="$(VF_LIB="$LIB" VF_CFG="$CONFIG_PATH" VF_ARB="$ARBITRATED_TOGGLES" node -e "$NODE_PROG" 2>/dev/null)"
NODE_RC=$?

if [ "$NODE_RC" -ne 0 ]; then
  say "clés connues illisibles depuis $LIB ou $CONFIG_PATH illisible — rien à constater."
  exit 3
fi

# --- Comparaison et mise en forme (côté bash) ---------------------------------------------------
# Retire les guillemets encadrants d'un jeton JSON. Les échappements internes (\uXXXX pour un octet
# de contrôle) sont VOLONTAIREMENT conservés : c'est ce qui garantit qu'aucun octet brut hostile ne
# ressort dans la sortie de session.
unq() { local s="$1"; s="${s#\"}"; s="${s%\"}"; printf '%s' "$s"; }

BLOCKS=""
SUBKEYS=""
TOGGLE_LINES=""
# ACCUMULATEUR ≠ VALEUR : le fichier audité est hostile par hypothèse et peut porter une clé VIDE
# ("" ou une sous-clé vide). Tester la vacuité de la chaîne accumulée confondrait « rien accumulé »
# et « une seule clé, vide » — une entrée de deux octets faisait alors taire TOUT le volet « clés
# inconnues ». Le nombre d'entrées est donc compté, jamais déduit de la chaîne.
N_BLOCKS=0
N_SUBKEYS=0
N_TOGGLES=0

# Un nom de clé vide n'est rien à l'écran : il est rendu sous sa forme JSON ("") pour rester
# lisible et actionnable, plutôt que d'imprimer un blanc entre deux virgules.
vis() { [ -n "$1" ] && printf '%s' "$1" || printf '%s' '""'; }

while IFS="$(printf '\t')" read -r kind f1 f2; do
  [ -n "$kind" ] || continue
  case "$kind" in
    UNKNOWN_BLOCK)
      k="$(vis "$(unq "$f1")")"
      if [ "$N_BLOCKS" -eq 0 ]; then BLOCKS="$k"; else BLOCKS="$BLOCKS, $k"; fi
      N_BLOCKS=$((N_BLOCKS+1)) ;;
    UNKNOWN_KEY)
      k="$(vis "$(unq "$f1")")"
      if [ "$N_SUBKEYS" -eq 0 ]; then SUBKEYS="$k"; else SUBKEYS="$SUBKEYS, $k"; fi
      N_SUBKEYS=$((N_SUBKEYS+1)) ;;
    TOGGLE_DEFAULT)
      t="$(unq "$f1")"; v="$(unq "$f2")"
      TOGGLE_LINES="${TOGGLE_LINES}             - ${t} : non écrit, au défaut amont (${v})
"
      N_TOGGLES=$((N_TOGGLES+1)) ;;
    TOGGLE_ABSENT)
      # Le script n'observe QUE l'absence de défaut lisible. Il n'observe pas POURQUOI, et
      # n'invoque donc aucune cause (« résolu par la capability elle-même » était une cause
      # FABRIQUÉE : node_repair/node_repair_budget ne sont pas des capabilities).
      t="$(unq "$f1")"
      TOGGLE_LINES="${TOGGLE_LINES}             - ${t} : non écrit, et sans défaut lisible dans le moteur — aucune valeur à afficher
"
      N_TOGGLES=$((N_TOGGLES+1)) ;;
  esac
done <<EOF
$RAW
EOF

SIGNAL=0

if [ "$N_BLOCKS" -gt 0 ]; then
  printf '%s\n' "[gsd-config] clés inconnues du moteur GSD installé dans ${CONFIG_PATH} : ${BLOCKS}"
  printf '%s\n' "             → le moteur les ignore ; les retirer ou écrire leur équivalent amont."
  SIGNAL=1
fi

if [ "$N_SUBKEYS" -gt 0 ]; then
  printf '%s\n' "[gsd-config] sous-clés inconnues sous un conteneur connu : ${SUBKEYS}"
  printf '%s\n' "             → le moteur les ignore ; les retirer ou écrire leur équivalent amont."
  SIGNAL=1
fi

if [ "$N_TOGGLES" -gt 0 ]; then
  printf '%s\n' "[gsd-config] toggles de cycle non écrits dans ${CONFIG_PATH} — ce lab les pilote par omission :"
  printf '%s' "$TOGGLE_LINES"
  printf '%s\n' "             → les écrire à une valeur décidée rend le choix explicite."
  SIGNAL=1
fi

if [ "$SIGNAL" -eq 1 ]; then
  say "signal émis sur $CONFIG_PATH (moteur lu depuis $LIB)."
  exit 0
fi

say "$CONFIG_PATH est aligné sur le moteur ($LIB) — rien à signaler."
exit 3
