#!/usr/bin/env node
// agent-to-codex.mjs — Adaptateur VibeFlow -> rôle Codex (Phase 38, lot 5, ADPT-01).
//
// Conversion PURE (aucun effet de bord disque) : frontmatter + corps Markdown d'un agent
// VibeFlow -> { toml, digest }. Le mapping est ALIGNÉ sur celui mesuré dans l'importeur natif
// Codex 0.150.1 (`external-agent-migration`, commande `/import`) — jamais un mapping inventé :
//   permissionMode -> sandbox_mode (non porté ici, aucun champ source équivalent chez VibeFlow)
//   corps markdown  -> developer_instructions
//   effort          -> model_reasoning_effort
// AUCUNE trace de tools/disallowedTools dans ce mapping — ils sont déclarés PENDING, jamais
// simulés sous une clé inventée de [tools] (piège n°2 mesuré, 38-CONTEXT.md).
//
// Champs requis par le binaire Codex 0.150.1 (mesuré, pas la doc) : name, description,
// developer_instructions. Le reste est un override optionnel.
//
// Zéro dépendance npm — Node built-in uniquement (T-38-SC : accepté, aucun paquet externe).

import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

/**
 * Découpe un agent VibeFlow en frontmatter (objet clé -> valeur brute, chaînes) + corps.
 * Motif `---` identique à celui déjà utilisé côté bash dans ce dépôt (délimiteur de bloc en
 * tête de fichier, sur sa propre ligne).
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
  for (const line of fmLines) {
    const m = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (m) {
      frontmatter[m[1]] = m[2].trim();
    }
  }
  return { frontmatter, body };
}

/** Échappe une chaîne pour un TOML basic string simple ("..."), une ligne. */
function escapeTomlBasic(str) {
  return str.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n');
}

/**
 * Échappe une chaîne pour un TOML multi-line basic string ("""...""").
 * Deux passes, dans cet ordre : backslashes d'abord (sinon la seconde passe introduirait des
 * backslashes non échappés), puis toute séquence de trois guillemets ou plus — jamais tronquer
 * le corps, jamais perdre un caractère : chaque `"""` devient `""\"` (le contenu reste lisible,
 * le TOML reste valide — cf. spec TOML : un guillemet échappé casse la séquence de fermeture).
 */
function escapeTomlMultiline(str) {
  let s = str.replace(/\\/g, '\\\\');
  s = s.replace(/"""/g, '""\\"');
  return s;
}

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

  tomlLines.push(`name = "${escapeTomlBasic(frontmatter.name)}"`);
  digest.push({ field: 'name', status: 'PRESERVED' });

  tomlLines.push(`description = "${escapeTomlBasic(frontmatter.description)}"`);
  digest.push({ field: 'description', status: 'PRESERVED' });

  tomlLines.push(`developer_instructions = """\n${escapeTomlMultiline(body)}\n"""`);
  digest.push({ field: 'developer_instructions', status: 'PRESERVED', note: 'corps Markdown source, intégral' });

  if (frontmatter.model) {
    tomlLines.push(`model = "${escapeTomlBasic(frontmatter.model)}"`);
    digest.push({ field: 'model', status: 'PRESERVED' });
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
