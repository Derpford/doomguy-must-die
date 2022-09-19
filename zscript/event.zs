class AttackTokenHandler : EventHandler {
    // Takes care of giving players their attack tokens at the start of the level.

    override void WorldThingSpawned(WorldEvent e) {
        if (e.Thing is "PlayerPawn") {
            console.printf("Skill level: %d",skill);
            e.Thing.GiveInventory("AttackToken",skill);
        }
    }
}