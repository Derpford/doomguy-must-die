extend class DMDMonster {
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

            if (!CheckSight(mo)) {
                continue;
            }

            Vector3 dv = Vec3To(mo);
            Vector3 dir = dv.unit();
            Double dist = dv.length();

            if (dist > radius) {
                continue;
            } 

            // Now we spawn some zappy particles and do damage.
            DrawLine(dv,"00FFFF",SPF_FULLBRIGHT);
            mo.DamageMobj(invoker,invoker,dmg,mod);
            mo.Vel3DFromAngle(speed,AngleTo(mo,true),pitch);
        }
    }
}

mixin class ParticleLines {
}

mixin class Shooter {
    // The shooty function.

    action Actor Shoot(String what, double speed = 0.0, Vector2 spread = (0,0), Vector2 aoffs = (0,0), Vector2 poffs = (0,0), double foroffs = 0) {
        // Fire a projectile at our current angle and pitch.
        // No hitscans!
        let it = invoker.Spawn(what,invoker.pos);
        if (it) {
            if (invoker.bISMONSTER) {
                it.target = invoker;
            } else if (invoker.target) {
                it.target = invoker.target;
            }
            if (speed == 0.0) {speed = it.speed;}
            double ang = invoker.angle+aoffs.x+frandom(-spread.x,spread.x);
            double pit = invoker.pitch+aoffs.y+frandom(-spread.y,spread.y);
            it.warp(invoker,it.speed+foroffs,poffs.x,poffs.y,ang,WARPF_NOCHECKPOSITION|WARPF_ABSOLUTEANGLE,heightoffset:0.5,radiusoffset:1.0,pitch:pit);
            // console.printf("Firing at %0.1f, %0.1f",ang,pit);
            // console.printf("Angle and pitch %0.1f, %0.1f",invoker.angle, invoker.pitch);
            it.Vel3DFromAngle(speed,ang,pit);
            it.angle = ang;
            it.pitch = pit;
        }
        return it;
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

mixin class FallingDebris {
    // Handles putting decorative gibs and such into and out of their crash states.
    bool crashed;

    void ProcessFall() {
        if (!crashed && pos.z == floorz) {
            SetState(ResolveState("Crash"));
            crashed = true;
        } else if (crashed && pos.z != floorz) {
            SetState(ResolveState("Spawn"));
            crashed = false;
        }
    }
}