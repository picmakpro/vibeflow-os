function extraireSessionChat(texte) {
  if (typeof texte !== 'string') return null;
  let session = null;
  texte.slice(0, 262144).split('\n\n').forEach((bloc) => {
    const ev = /^event: (.*)$/m.exec(bloc), dt = /^data: (.*)$/m.exec(bloc);
    if (!ev || ev[1] !== 'answer' || !dt) return;
    try { const d = JSON.parse(dt[1]); if (d && typeof d.session === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(d.session)) session = d.session; } catch (e) { void e; } // bloc illisible : ignoré
  });
  return session;
}
