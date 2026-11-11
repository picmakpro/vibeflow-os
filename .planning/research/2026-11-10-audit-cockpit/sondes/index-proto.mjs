// Prototype de mesure d'un index de frise : un passage complet sur les transcripts de sous-agents (et de sessions), agregats seulement.
// Aucun texte de conversation n'est lu au-dela de JSON.parse ni imprime : horodatages, identifiants de message, usage, noms d'outils, drapeaux.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import readline from 'node:readline';
const base = path.join(os.homedir(), '.claude', 'projects');
const prefix = process.argv[2]; // préfixe du dossier du lab sous ~/.claude/projects
const FRAIS = 180;
const q = (a, p) => (a.length ? a[Math.min(a.length - 1, Math.floor(p * a.length))] : 0);
const cibles = [];
for (const d of fs.readdirSync(base).filter((x) => x.startsWith(prefix))) {
  const dir = path.join(base, d);
  for (const s of fs.readdirSync(dir)) {
    if (s.endsWith('.jsonl')) { cibles.push({ f: path.join(dir, s), sorte: 'session', meta: null }); continue; }
    const sd = path.join(dir, s, 'subagents'); let ents = []; try { ents = fs.readdirSync(sd); } catch { continue; }
    for (const e of ents.filter((x) => x.endsWith('.jsonl'))) { let meta = null; try { meta = JSON.parse(fs.readFileSync(path.join(sd, e.replace(/\.jsonl$/, '.meta.json')), 'utf8')); } catch {} cibles.push({ f: path.join(sd, e), sorte: 'sous-agent', meta }); }
  }
}
const t0 = Date.now(); let octets = 0;
const res = [];
for (const c of cibles) {
  const st = fs.statSync(c.f); octets += st.size;
  const r = { sorte: c.sorte, taille: st.size, fini: c.meta?.finished === true, arrete: !!c.meta && 'stoppedByUser' in c.meta, role: c.meta?.agentType, debut: null, fin: null, silences: 0, silenceS: 0, silenceMax: 0, msgs: new Map(), outils: 0, erreurs: 0, enAttenteOutil: new Map(), dernierStop: null, dernierType: null, ctxMax: 0, tours: 0, compactions: 0, modeles: new Set(), fichiers: new Set(), ask: 0, refus: 0, bg: 0, timeouts: 0, lignes: 0, segments: 0, mtime: st.mtimeMs, handback: 0 };
  let prev = null;
  const rl = readline.createInterface({ input: fs.createReadStream(c.f, { encoding: 'utf8' }), crlfDelay: Infinity });
  for await (const l of rl) {
    if (!l) continue; r.lignes++;
    let d; try { d = JSON.parse(l); } catch { continue; }
    const ts = typeof d.timestamp === 'string' ? Date.parse(d.timestamp) : NaN;
    if (d.type === 'user' || d.type === 'assistant') {
      r.dernierType = d.type;
      if (Number.isFinite(ts)) {
        if (r.debut === null) r.debut = ts; r.fin = ts;
        if (prev !== null) { const e = (ts - prev) / 1000; if (e > FRAIS) { r.silences++; r.silenceS += e - FRAIS; if (e > r.silenceMax) r.silenceMax = e; r.segments++; } }
        prev = ts;
      }
    }
    if (d.type === 'assistant' && d.message) {
      const m = d.message; r.dernierStop = m.stop_reason ?? null; if (typeof m.model === 'string') r.modeles.add(m.model);
      if (m.id && m.usage) { const u = m.usage; r.msgs.set(m.id, { o: u.output_tokens || 0, c: (u.input_tokens || 0) + (u.cache_read_input_tokens || 0) + (u.cache_creation_input_tokens || 0) }); }
      for (const b of Array.isArray(m.content) ? m.content : []) if (b?.type === 'tool_use') { r.outils++; r.enAttenteOutil.set(b.id, b.name); if (b.name === 'AskUserQuestion') r.ask++; if (b.name === 'SubagentHandback') r.handback++; if (['Edit', 'Write', 'MultiEdit', 'NotebookEdit'].includes(b.name) && typeof b.input?.file_path === 'string') r.fichiers.add(b.input.file_path); if (b.name === 'Bash' && b.input?.run_in_background === true) r.bg++; }
    } else if (d.type === 'user') {
      for (const b of Array.isArray(d.message?.content) ? d.message.content : []) if (b?.type === 'tool_result') { r.enAttenteOutil.delete(b.tool_use_id); if (b.is_error === true) r.erreurs++; }
      if (d.permissionDecision?.decision === 'reject') r.refus++;
      if (d.toolUseResult && typeof d.toolUseResult === 'object') { if (d.toolUseResult.backgroundTaskId) r.bg++; if (d.toolUseResult.timedOutAfterMs) r.timeouts++; }
    } else if (d.type === 'system') { if (d.subtype === 'turn_duration') r.tours++; if (d.subtype === 'compact_boundary') r.compactions++; }
  }
  r.tokensOut = 0; for (const v of r.msgs.values()) { r.tokensOut += v.o; if (v.c > r.ctxMax) r.ctxMax = v.c; }
  r.nMsgs = r.msgs.size; r.pendants = r.enAttenteOutil.size; r.pendantNoms = [...r.enAttenteOutil.values()]; delete r.msgs; delete r.enAttenteOutil;
  res.push(r);
}
const dt = (Date.now() - t0) / 1000;
console.log(`passage complet: ${cibles.length} fichiers, ${(octets / 1048576).toFixed(0)} Mo en ${dt.toFixed(1)} s (${(octets / 1048576 / dt).toFixed(0)} Mo/s)`);
for (const sorte of ['sous-agent', 'session']) {
  const R = res.filter((x) => x.sorte === sorte); if (!R.length) continue;
  const dur = R.filter((x) => x.debut !== null).map((x) => (x.fin - x.debut) / 1000).sort((a, b) => a - b);
  const tot = dur.reduce((a, b) => a + b, 0), sil = R.reduce((a, x) => a + x.silenceS, 0);
  console.log(`\n== ${sorte} (n=${R.length}) ==`);
  console.log(`  duree (s): mediane=${q(dur, 0.5).toFixed(0)} p90=${q(dur, 0.9).toFixed(0)} max=${q(dur, 1).toFixed(0)} ; total=${(tot / 3600).toFixed(1)} h`);
  console.log(`  silences > ${FRAIS}s entre deux lignes user/assistant: fichiers concernes=${R.filter((x) => x.silences > 0).length} (${(100 * R.filter((x) => x.silences > 0).length / R.length).toFixed(0)} %), nb de silences=${R.reduce((a, x) => a + x.silences, 0)}, temps au-dela du seuil=${(sil / 3600).toFixed(1)} h (${(100 * sil / Math.max(1, tot)).toFixed(0)} % de la duree totale), plus long silence=${Math.max(...R.map((x) => x.silenceMax)).toFixed(0)} s ; >600s: ${R.filter((x) => x.silenceMax > 600).length} ; >1800s: ${R.filter((x) => x.silenceMax > 1800).length}`);
  const lg = R.map((x) => x.lignes).sort((a, b) => a - b), msg = R.map((x) => x.nMsgs).sort((a, b) => a - b), out = R.map((x) => x.outils).sort((a, b) => a - b), tk = R.map((x) => x.tokensOut).sort((a, b) => a - b), cx = R.map((x) => x.ctxMax).sort((a, b) => a - b);
  console.log(`  lignes: med=${q(lg, 0.5)} p90=${q(lg, 0.9)} max=${q(lg, 1)} ; messages API distincts: med=${q(msg, 0.5)} p90=${q(msg, 0.9)} max=${q(msg, 1)} ; outils: med=${q(out, 0.5)} p90=${q(out, 0.9)} max=${q(out, 1)}`);
  console.log(`  tokens de sortie (dedoublonnes par message.id): med=${q(tk, 0.5)} p90=${q(tk, 0.9)} max=${q(tk, 1)} total=${tk.reduce((a, b) => a + b, 0)} ; contexte max: med=${q(cx, 0.5)} p90=${q(cx, 0.9)} max=${q(cx, 1)}`);
  console.log(`  erreurs d'outil: total=${R.reduce((a, x) => a + x.erreurs, 0)} fichiers>=1: ${R.filter((x) => x.erreurs > 0).length} ; refus de permission: ${R.reduce((a, x) => a + x.refus, 0)} ; taches de fond (Bash): ${R.reduce((a, x) => a + x.bg, 0)} ; timeouts Bash: ${R.reduce((a, x) => a + x.timeouts, 0)} ; AskUserQuestion: ${R.reduce((a, x) => a + x.ask, 0)} ; compactions: ${R.reduce((a, x) => a + x.compactions, 0)} ; tours (turn_duration): ${R.reduce((a, x) => a + x.tours, 0)} ; fichiers ecrits distincts (Edit/Write): med=${q(R.map((x) => x.fichiers.size).sort((a, b) => a - b), 0.5)} max=${Math.max(...R.map((x) => x.fichiers.size))}`);
  const modeles = new Map(); for (const x of R) for (const m of x.modeles) modeles.set(m, (modeles.get(m) || 0) + 1);
  console.log('  modeles (fichiers):', [...modeles].sort((a, b) => b[1] - a[1]).map(([k, v]) => `${k}=${v}`).join('  '), ' ; fichiers a >1 modele:', R.filter((x) => x.modeles.size > 1).length);
  if (sorte === 'sous-agent') {
    const cat = (x) => `${x.fini ? 'finished:true' : x.arrete ? 'stoppedByUser' : 'sans drapeau'} | dernier=${x.dernierType}/${x.dernierStop} | outil pendant=${x.pendants ? 'oui' : 'non'}`;
    const m = new Map(); for (const x of R) m.set(cat(x), (m.get(cat(x)) || 0) + 1);
    console.log('  etat final (drapeau meta | derniere ligne | tool_use sans resultat) :'); for (const [k, v] of [...m].sort((a, b) => b[1] - a[1])) console.log(`    ${String(v).padStart(4)}  ${k}`);
    const sansDrapeau = R.filter((x) => !x.fini && !x.arrete);
    const pend = new Map(); for (const x of sansDrapeau) for (const n of x.pendantNoms) pend.set(n.startsWith('mcp__') ? 'mcp' : n, (pend.get(n.startsWith('mcp__') ? 'mcp' : n) || 0) + 1);
    console.log('  sans drapeau: outils laisses pendants:', [...pend].map(([k, v]) => `${k}=${v}`).join('  ') || '(aucun)', ' ; avec SubagentHandback:', sansDrapeau.filter((x) => x.handback > 0).length, '/', sansDrapeau.length, ' ; finis avec handback:', R.filter((x) => x.fini && x.handback > 0).length, '/', R.filter((x) => x.fini).length);
    // ecart entre la derniere ligne horodatee et la date de modification du fichier (le cockpit date la fin d'un termine par mtime)
    const ec = R.filter((x) => x.fin).map((x) => Math.abs(x.mtime - x.fin) / 1000).sort((a, b) => a - b);
    console.log(`  |mtime - derniere ligne user/assistant| (s): med=${q(ec, 0.5).toFixed(1)} p90=${q(ec, 0.9).toFixed(1)} max=${q(ec, 1).toFixed(0)} ; > 60 s: ${ec.filter((x) => x > 60).length}`);
  } else {
    const m = new Map(); for (const x of R) { const k = `dernier=${x.dernierType}/${x.dernierStop} | outil pendant=${x.pendants ? 'oui' : 'non'}`; m.set(k, (m.get(k) || 0) + 1); }
    console.log('  etat final (derniere ligne | tool_use sans resultat) :'); for (const [k, v] of [...m].sort((a, b) => b[1] - a[1])) console.log(`    ${String(v).padStart(4)}  ${k}`);
  }
}
// taille d'un index resume (une entree par agent, sans texte)
const resume = res.map((x) => ({ s: x.sorte[0], d: x.debut, f: x.fin, n: x.nMsgs, o: x.outils, e: x.erreurs, t: x.tokensOut, c: x.ctxMax, m: [...x.modeles], p: x.pendants, r: x.role, k: x.silences }));
console.log(`\nindex resume (1 entree par transcript, sans texte): ${(JSON.stringify(resume).length / 1024).toFixed(0)} Ko pour ${resume.length} transcripts ; segments d'activite (coupes aux silences > ${FRAIS}s): ${res.reduce((a, x) => a + x.segments + 1, 0)}`);
