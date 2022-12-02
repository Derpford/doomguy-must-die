mixin class RadiusPush {
    // A handy function that tosses targets with the specified pitch in an AoE.

    void RadiusPush(double speed, double radius, double pitch) {
        ThinkerIterator it = ThinkerIterator.Create("Actor");
        Actor mo;
        while (mo = Actor(it.next())) {
            if (mo == self || !mo.bSHOOTABLE) {
                continue;
            }

            Vector3 dv = Vec3To(mo);
            Vector3 dir = dv.unit();
            Double dist = dv.length();

            if (dist > radius) {
                continue;
            } 
            mo.Vel3DFromAngle(speed,AngleTo(mo,true),pitch);
        }
    }

    action void RadiusShock(double speed, double radius, double pitch, int dmg, Name mod) {
        // Does damage too! And spawns particles!
        ThinkerIterator it = ThinkerIterator.Create("Actor");
        Actor mo;
        while (mo = Actor(it.next())) {
            if (mo == invoker || !mo.bSHOOTABLE) {
                continue;
            }

            Vector3 dv = Vec3To(mo);
            Vector3 dir = dv.unit();
            Double dist = dv.length();

            if (dist > radius) {
                continue;
            } 

            // Now we spawn some zappy particles and do damage.
            for(int i = 0; i < dist; i += random(3,6)) {
                A_SpawnParticle("00FFFF",SPF_FULLBRIGHT,35,frandom(3,6),0,dir.x * i, dir.y * i, dir.z * i);
            }
            mo.DamageMobj(invoker,invoker,dmg,mod);
            mo.Vel3DFromAngle(speed,AngleTo(mo,true),pitch);
        }
    }
}

class DMDMonster : Actor abstract {
    // The base class for all Doomguy Must Die enemies.
    // This holds some key bits of stuff, including the Attack Token System details.

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

    action bool CanAttack() {
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
        if (AttackTarget && AttackTarget != self) {
            AttackTarget.GiveInventory("AttackToken",CountInv("AttackToken"));
        }
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
        invoker.TakeInventory("AttackToken",1);
        if (invoker.AttackTarget && invoker.AttackTarget != self) {
            invoker.AttackTarget.GiveInventory("AttackToken",1);
        }
        invoker.AttackTarget = invoker; // Clear our attack target.
    }

    action Actor Shoot(String what, double speed = 0.0, Vector2 spread = (0,0), Vector2 aoffs = (0,0)) {
        // Fire a projectile at our current angle and pitch.
        // No hitscans!
        Vector2 xy = AngleToVector(invoker.angle,invoker.radius);
        Vector3 spawnpos = (xy.x,xy.y,invoker.height/2.);
        let it = invoker.Spawn(what,invoker.pos+spawnpos);
        if (it) {
            it.target = invoker;
            if (speed == 0.0) {speed = it.speed;}
            double ang = invoker.angle+aoffs.x+frandom(-spread.x,spread.x);
            double pit = invoker.pitch+aoffs.y+frandom(-spread.y,spread.y);
            // console.printf("Firing at %0.1f, %0.1f",ang,pit);
            // console.printf("Angle and pitch %0.1f, %0.1f",invoker.angle, invoker.pitch);
            it.Vel3DFromAngle(speed,ang,pit);
            it.angle = ang;
            it.pitch = pit;
        }
        return it;
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

mixin class ParticleTracer {
    // Spawns particles around itself.

    action void SpawnTrail(double size, double length,Color col,Vector3 offs = (0,0,0),Vector3 spread = (0,0,0), int start = 2, double lifetime = 1) {
        for (int i = start; i < length+start; i++) {
            Vector3 spawnpos = invoker.vel.unit() * i * -1;
            Vector3 spreadpos = (
                    frandom(-spread.x,spread.x),
                    frandom(-spread.y,spread.y),
                    frandom(-spread.z,spread.z)
                    );
            double psize = size * ((length - i) / length);
            A_SpawnParticle(col,SPF_FULLBRIGHT,lifetime,psize,0,spawnpos.x+offs.x+spreadpos.x,spawnpos.y+offs.y+spreadpos.y,spawnpos.z+offs.z+spreadpos.z);
        }
    }
}