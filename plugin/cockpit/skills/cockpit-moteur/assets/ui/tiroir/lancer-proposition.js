function corpsProposition({ cible, verbe, chat, livre }) {
  const corps = { cible, verbe };
  if (livre === true && typeof chat === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(chat)) corps.chat = chat;
  return corps;
}
