#!/usr/bin/env node
// agent-to-codex.mjs — Adaptateur VibeFlow -> rôle Codex (Phase 38, lot 5, ADPT-01).
//
// Conversion PURE (aucun effet de bord disque) : frontmatter + corps Markdown d'un agent
// VibeFlow -> { toml, digest }. Mapping ALIGNÉ sur celui mesuré dans l'importeur natif Codex
// 0.150.1 (`external-agent-migration`, `/import`) — jamais un mapping inventé :
//   corps markdown -> developer_instructions · effort -> model_reasoning_effort
//   model Claude   -> table CLAUDE_TO_CODEX_MODEL (mesurée, RIEN d'inventé, voir plus bas)
// AUCUNE trace de tools/disallowedTools : déclarés PENDING, jamais une clé [tools] inventée
// (piège n°2 mesuré, 38-CONTEXT.md). Champs requis par Codex 0.150.1 (mesuré, pas la doc) :
// name, description, developer_instructions. Zéro dépendance npm (T-38-SC).

import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

/**
 * Décode un scalaire replié/littéral YAML (`>`, `|`, `>-`, `|-`, `>+`, `|+`) depuis les lignes
 * qui suivent `clé: <indicateur>`. Corrige le piège n°2 (38-CONTEXT.md) : l'ancienne regex
 * mono-ligne capturait l'indicateur seul (`description = ">"`), jamais le texte replié.
 */
function parseBlockScalar(fmLines, startIndex, chomp, style) {
  let i = startIndex;
  const blockLines = [];
  let blockIndent = null;
  while (i < fmLines.length) {
    const l = fmLines[i];
    if (l.trim() === '') {
      blockLines.push('');
      i++;
      continue;
    }
    const indentMatch = l.match(/^(\s+)/);
    if (!indentMatch) break; // dédent : fin du bloc
    const indent = indentMatch[1].length;
    if (blockIndent === null) blockIndent = indent;
    if (indent < blockIndent) break;
    blockLines.push(l.slice(blockIndent));
    i++;
  }

  let trailingEmpty = 0;
  while (blockLines.length && blockLines[blockLines.length - 1] === '') {
    blockLines.pop();
    trailingEmpty++;
  }

  let value;
  if (style === '|') {
    value = blockLines.join('\n'); // littéral : sauts de ligne préservés tels quels
  } else {
    // replié (>) : lignes non vides consécutives jointes par un espace, ligne vide -> \n
    let out = '';
    let prevBlank = true;
    for (const bl of blockLines) {
      if (bl === '') {
        out += '\n';
        prevBlank = true;
      } else {
        if (!prevBlank && out.length) out += ' ';
        out += bl;
        prevBlank = false;
      }
    }
    value = out;
  }

  if (chomp === '+') {
    value += '\n'.repeat(trailingEmpty); // keep
  } else if (chomp !== '-' && value.length) {
    value += '\n'; // clip (défaut) : exactement un \n final si le bloc n'est pas vide
  }

  return { value, nextIndex: i };
}

/**
 * Découpe un agent VibeFlow en frontmatter (objet clé -> valeur) + corps. Parseur YAML
 * frontmatter MINIMAL mais RÉEL — pas une regex mono-ligne (piège n°2, corrigé Phase 38) :
 * gère les scalaires simples ET repliés/littéraux. Les listes YAML (`- item`) restent hors
 * périmètre — aucun champ consommé ici (name/description/model/effort/memory/tools/
 * disallowedTools/vf-internal) n'en est une ; une ligne de liste reste ignorée, comme avant.
 */
function splitFrontmatter(sourceMarkdown) {
  const lines = sourceMarkdown.split('\n');
  if (lines[0] !== '---') {
    throw new Error('agent-to-codex: frontmatter absent (le fichier ne commence pas par "---")');
  }
  let end = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i] === '---') {
      end = i;
      break;
    }
  }
  if (end === -1) {
    throw new Error('agent-to-codex: frontmatter jamais refermé (pas de second "---")');
  }
  const fmLines = lines.slice(1, end);
  const body = lines.slice(end + 1).join('\n').replace(/^\n+/, '');

  const frontmatter = {};
  let i = 0;
  while (i < fmLines.length) {
    const line = fmLines[i];
    if (!line.trim()) {
      i++;
      continue;
    }
    const m = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (!m) {
      i++;
      continue;
    }
    const key = m[1];
    const rest = m[2].trim();
    const blockMatch = rest.match(/^([>|])([+-]?)\d*\s*$/);
    if (blockMatch) {
      const { value, nextIndex } = parseBlockScalar(fmLines, i + 1, blockMatch[2], blockMatch[1]);
      frontmatter[key] = value;
      i = nextIndex;
      continue;
    }
    let val = rest;
    if (val.length >= 2 && ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'")))) {
      val = val.slice(1, -1);
    }
    frontmatter[key] = val;
    i++;
  }
  return { frontmatter, body };
}

/** Échappe une chaîne pour un TOML basic string simple ("..."), une ligne. */
function escapeTomlBasic(str) {
  return str.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n');
}

/**
 * Échappe une chaîne pour un TOML multi-line basic string ("""...""").
 * Backslashes d'abord (sinon la seconde passe en introduirait de non échappés), puis toute
 * séquence de 3+ guillemets -> `""\"` : jamais tronquer le corps, jamais perdre un caractère.
 */
function escapeTomlMultiline(str) {
  let s = str.replace(/\\/g, '\\\\');
  s = s.replace(/"""/g, '""\\"');
  return s;
}

/**
 * Table de correspondance modèle Claude -> Codex, MESURÉE (jamais inventée) sur Codex 0.150.1,
 * 2026-08-28, compte ChatGPT de ce poste. Un rôle recopiant `opus`/`sonnet`/`haiku` tel quel
 * échoue au spawn — mesuré : "The 'opus' model is not supported when using Codex with a
 * ChatGPT account." Cibles OBSERVÉES disponibles ici (PAS une liste officielle exhaustive
 * Codex) : gpt-5.6-terra, gpt-5.5, gpt-5.4-mini — par capacité décroissante côté Claude ->
 * décroissante côté Codex mesuré. Modèle source absent d'ici = ROUGE (voir plus bas), AUCUN
 * repli silencieux.
 */
const CLAUDE_TO_CODEX_MODEL = Object.freeze({
  opus: 'gpt-5.6-terra',
  sonnet: 'gpt-5.5',
  haiku: 'gpt-5.4-mini',
});

/**
 * Conversion pure : agent VibeFlow (Markdown + frontmatter Claude Code) -> rôle Codex.
 * Retourne { toml, digest }. `digest` est un tableau ordonné de { field, status, note } —
 * jamais un champ absent pour memory/tools/disallowedTools/vf-internal (déclaration explicite,
 * même quand la source ne porte pas le champ).
 */
export function convertAgentToCodexRole(sourceMarkdown) {
  const { frontmatter, body } = splitFrontmatter(sourceMarkdown);

  if (!frontmatter.name) {
    throw new Error('agent-to-codex: champ "name" absent du frontmatter — requis par Codex 0.150.1');
  }
  if (!frontmatter.description) {
    throw new Error('agent-to-codex: champ "description" absent du frontmatter — requis par Codex 0.150.1');
  }
  if (!body.trim()) {
    throw new Error('agent-to-codex: corps Markdown vide — developer_instructions est requis et non vide par Codex 0.150.1');
  }

  const tomlLines = [];
  const digest = [];

  tomlLines.push(`name = "${escapeTomlBasic(frontmatter.name.trim())}"`);
  digest.push({ field: 'name', status: 'PRESERVED' });

  tomlLines.push(`description = "${escapeTomlBasic(frontmatter.description.trim())}"`);
  digest.push({ field: 'description', status: 'PRESERVED' });

  tomlLines.push(`developer_instructions = """\n${escapeTomlMultiline(body)}\n"""`);
  digest.push({ field: 'developer_instructions', status: 'PRESERVED', note: 'corps Markdown source, intégral' });

  // model : jamais une recopie littérale Claude -> Codex (piège mesuré, cf. CLAUDE_TO_CODEX_MODEL
  // ci-dessus). Source inconnue -> ROUGE explicite, aucun repli silencieux (D-38 bloquant 1).
  if (frontmatter.model) {
    const sourceModel = frontmatter.model.trim();
    const targetModel = CLAUDE_TO_CODEX_MODEL[sourceModel];
    if (!targetModel) {
      throw new Error(`agent-to-codex: modèle source "${sourceModel}" absent de CLAUDE_TO_CODEX_MODEL — aucun repli silencieux, ajouter le mapping avant de convertir ce rôle`);
    }
    tomlLines.push(`model = "${escapeTomlBasic(targetModel)}"`);
    digest.push({ field: 'model', status: 'MAPPED', note: `source "${sourceModel}" -> cible Codex "${targetModel}" (table CLAUDE_TO_CODEX_MODEL, mesurée sur Codex 0.150.1)` });
  } else {
    digest.push({ field: 'model', status: 'ABSENT', note: 'aucun model en frontmatter source' });
  }

  // effort -> model_reasoning_effort : MÊME mapping que /import Codex, jamais un nom inventé.
  if (frontmatter.effort) {
    tomlLines.push(`model_reasoning_effort = "${escapeTomlBasic(frontmatter.effort)}"`);
    digest.push({ field: 'effort', status: 'PRESERVED', note: 'mappé vers model_reasoning_effort (mapping /import Codex)' });
  } else {
    digest.push({ field: 'effort', status: 'ABSENT', note: 'aucun effort en frontmatter source' });
  }

  // memory : schéma Codex rejette `memory` (unknown field). Perte déclarée, jamais un trou
  // comblé (D-37-2, 38-CONTEXT.md). Toujours présent au digest, présent ou non côté source.
  if (frontmatter.memory) {
    digest.push({ field: 'memory', status: 'LOST', note: `valeur source "${frontmatter.memory}" — capacité mémoire par projet Claude-only, non représentable côté Codex 0.150.1` });
  } else {
    digest.push({ field: 'memory', status: 'LOST', note: 'aucune valeur source — champ non représentable côté Codex de toute façon' });
  }

  // tools/disallowedTools : aucun équivalent déclaratif mesuré (ToolsToml = bascules de
  // fonctionnalités, pas une allowlist). PENDING, jamais écrit sous une clé inventée de
  // [tools] (piège n°2 — T-38-15).
  if (frontmatter.tools) {
    digest.push({ field: 'tools', status: 'PENDING', note: `valeur source "${frontmatter.tools}" — aucun équivalent [tools] mesuré, PENDING tant que [permissions] par rôle n'est pas confirmé fonctionnel` });
  } else {
    digest.push({ field: 'tools', status: 'PENDING', note: 'aucune valeur source — statut PENDING conservé (aucun mécanisme de restriction par rôle mesuré fonctionnel à ce jour)' });
  }
  if (frontmatter.disallowedTools) {
    digest.push({ field: 'disallowedTools', status: 'PENDING', note: `valeur source "${frontmatter.disallowedTools}" — même statut que tools` });
  } else {
    digest.push({ field: 'disallowedTools', status: 'PENDING', note: 'aucune valeur source — statut PENDING conservé' });
  }

  // vf-internal : l'adaptateur n'écrit JAMAIS [agents.<n>]/nickname dans config.toml, donc
  // aucun rôle posé n'obtient de raccourci d'invocation utilisateur — vf-internal ou non, le
  // comportement est le même par omission d'écriture, pas par un mécanisme dédié.
  if (frontmatter['vf-internal']) {
    digest.push({ field: 'vf-internal', status: 'PRESERVED_BY_OMISSION', note: `valeur source "${frontmatter['vf-internal']}" — aucun [agents.<n>] jamais écrit dans config.toml, donc aucun raccourci d'invocation exposé, cohérent avec l'intention` });
  } else {
    digest.push({ field: 'vf-internal', status: 'PRESERVED_BY_OMISSION', note: 'absent côté source — même comportement (aucun raccourci exposé)' });
  }

  const toml = tomlLines.join('\n') + '\n';
  return { toml, digest };
}

/** Formatte le digest en lignes "field: STATUS (note)" — une ligne par champ, jamais une case vide. */
export function formatDigest(digest) {
  return digest
    .map((d) => `${d.field}: ${d.status}${d.note ? ` — ${d.note}` : ''}`)
    .join('\n');
}

// --- Mode CLI : node agent-to-codex.mjs <agent.md> --out <role.toml> -------------------------
function isMainModule() {
  if (process.argv.length < 2) return false;
  try {
    return fileURLToPath(import.meta.url) === process.argv[1];
  } catch {
    return false;
  }
}

if (isMainModule()) {
  const args = process.argv.slice(2);
  const inputPath = args[0];
  const outIdx = args.indexOf('--out');
  const outPath = outIdx !== -1 ? args[outIdx + 1] : null;

  if (!inputPath) {
    console.error('usage: node agent-to-codex.mjs <agent.md> [--out <role.toml>]');
    process.exit(2);
  }

  try {
    const source = readFileSync(inputPath, 'utf8');
    const { toml, digest } = convertAgentToCodexRole(source);
    if (outPath) {
      writeFileSync(outPath, toml, 'utf8');
    } else {
      process.stdout.write(toml);
    }
    console.error(formatDigest(digest));
  } catch (err) {
    console.error(`agent-to-codex: ${err.message}`);
    process.exit(1);
  }
}
