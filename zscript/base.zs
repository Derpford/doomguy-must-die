
class DMDMonster : Actor abstract {
    // The base class for all Doomguy Must Die enemies.
    // This holds some key bits of stuff, including the Attack Token System details.

    mixin Shooter;

    default {
        +DOHARMSPECIES; // Infighting for days!
        Monster;
    }

    Actor AttackTarget; // Who did we take an attack token from?

    abstract State ChooseAttack();
    // Returns an attack State to jump to.
    // Every enemy in this mod should have 2 or more attacks, ideally with unique tells!

    action void Aim(double angle = 0, double pitch = 0, int flags = FAF_MIDDLE, Vector2 offs = (0,0)) {
        A_FaceTarget(angle, pitch,offs.x,offs.y,flags:flags);
    }

    override void Tick() {
        Super.Tick();
        bool debug = false;
        if (debug && countinv("AttackToken") > 0) {
            Console.printf("%s holding %d attacktokens",GetTag(),countinv("AttackToken"));
        }
    }

    action bool CanAttack() {
        // Console.printf("%s attempting an attack against %s",invoker.GetTag(),invoker.target.GetTag());
        if (invoker.AttackTarget && invoker.AttackTarget != invoker) { // We already have an attack target!
            return true;
        }

        if (invoker.target) { // If we have a target...
            let plr = invoker.target;

            if (plr.CountInv("HeavenAndHell") > 0) { // HEAVEN AND HELL mode turns off attack token system entirely.
                return true;
            }

            if (plr is "PlayerPawn") { // And it's a player...
                if (plr.CountInv("AttackToken") > 0) { // And they have attack tokens to spare...
                    invoker.AttackTarget = plr;
                    plr.TakeInventory("AttackToken",1);
                    invoker.GiveInventory("AttackToken",1); // Take one of their attack tokens, so that we can attack it!
                }
            } else {
                // If our current target isn't a player, don't use the attack token system.
                return true;
            }
        }

        return (invoker.CountInv("AttackToken") > 0); // Normally, a creature only attacks if it has an attack token.
    }

    override void Die(Actor src, Actor inf, int flags, Name type) {
        EndAttack();
        super.Die(src,inf,flags,type);
    }

    action State StartAttack() {
        if (target && CanAttack()) {
            return invoker.ChooseAttack();
        } else {
            return ResolveState(null);
        }
    }

    action void EndAttack() {
        // Give back the attack token we took.
        // console.printf("%s giving an attack token back to %s",invoker.GetTag(),invoker.AttackTarget.GetTag());
        invoker.TakeInventory("AttackToken",1);
        if (invoker.AttackTarget && invoker.AttackTarget != self) {
            invoker.AttackTarget.GiveInventory("AttackToken",1);
        }
        invoker.AttackTarget = invoker; // Clear our attack target.
    }

}


class AttackToken : Inventory {
    // A token that determines whether something can attack. The player holds 1-5 based on difficulty, and enemies take one when attacking and return it when they're done.
    default {
        Inventory.Amount 1;
        Inventory.MaxAmount 5; 
        +Inventory.KEEPDEPLETED;
    }

    override void Travelled() {
        if (owner) {
            owner.TakeInventory("AttackToken",5);
            owner.GiveInventory("AttackToken",skill+1);
        }
    }
}

class HeavenAndHell : Inventory {
    // A player with this item has triggered Heaven And Hell mode.
    default {
        Inventory.Amount 1;
        Inventory.MaxAmount 1;
    }
}
