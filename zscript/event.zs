class AttackTokenHandler : EventHandler {
    // Takes care of giving players their attack tokens at the start of the level.

    override void WorldThingSpawned(WorldEvent e) {
        let plr = PlayerPawn(e.Thing);
        if (plr) {
            // console.printf("Skill level: %d",skill+1);
            plr.GiveInventory("AttackToken",skill+1);
        }
    }
}