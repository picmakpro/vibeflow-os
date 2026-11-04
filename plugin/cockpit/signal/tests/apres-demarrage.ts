// Depuis P68-D-41, session.start ne attend plus l'émetteur : le premier rafraîchissement part en arrière-plan.
// Un test qui monte la pane aussitôt laisse d'abord finir ce rafraîchissement (le faux émetteur répond sans délai).
export const apresDemarrage = () => new Promise<void>(r => setTimeout(r, 120))
