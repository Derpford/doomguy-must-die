class Skully : DMDMonster replaces LostSoul {
    // A floating nuisance.
    // 1. Instead of charging directly at you, it likes to charge to either side, periodically spitting projectiles out at 90 degree offsets. Each of these projectiles does 25 damage.
    // 2. When seriously injured, it starts charging directly at you, doing 20 damage on impact. This is less dangerous than the risk of accidentally rocketing yourself in the face.
    default {
        Health 80; // Easier to kill.
        Radius 16;
        Height 48; // Shorter?
        Mass 25; // Lighter
        DamageFunction (20);
        Speed 10; // Faster.
        +FLOAT;
        +NOGRAVITY;
        +RETARGETAFTERSLAM;
        +DONTFALL;
        +BRIGHT;
        PainChance 256;
        AttackSound "skull/melee";
		PainSound "skull/pain";
		DeathSound "skull/death";
		ActiveSound "skull/active";
		RenderStyle "Translucent";
        Alpha 0.7;
    }

    override state ChooseAttack() {
        if (health < 30) {
            return ResolveState("Kamikaze");
        } else {
            return ResolveState("Strafe");
        }
    }

    void StrafeStart() {
        double ang = 30;
        if (random(0,1)) { ang *= -1; }
        Aim(0,270,offs:(ang,0));
        VelFromAngle(frandom(20,30),angle);
    }

    State SkullyStrafe() {
        if (vel.length() < 5) {
            return ResolveState("StrafeEnd");
        } else {
            vel = vel.unit() * (vel.length() - 3);
            double spd = frandom(10,15);
            double pit = -(spd * frandom(1.0,2.0));
            double ang = 105;
            double foroffs = 32;
            A_StartSound("monster/hlnatk");
            Shoot("SkullyFire",spd,aoffs:(ang,pit),foroffs:foroffs);
            Shoot("SkullyFire",spd,aoffs:(-ang,pit),foroffs:foroffs);
            return ResolveState(null);
        }
    }

    states {
        Spawn:
            SKUL AB Random(4,8) A_Look();
            Loop;
        
        See:
            SKUL AABB 3 A_Chase();
            Loop;
        
        Missile:
            SKUL C 3 A_StartSound("skull/melee");
            SKUL C 3 StartAttack();
            SKUL A 3;
            Goto See;
        
        Strafe:
            SKUL C 6 StrafeStart();
        StrafeLoop:
            SKUL CD 6 SkullyStrafe();
            Loop;
        StrafeEnd:
            SKUL C 12 EndAttack();
            Goto See;
        
        Kamikaze:
            SKUL C 6 Aim();
            SKUL D 6 A_SkullAttack();
        KamikazeLoop:
            SKUL CD 3;
            Loop;
        
        Slam:
            SKUL E 8 A_Pain();
            SKUL F 4 A_Die();
            Goto Death;
        
        Pain:
            SKUL E 0 A_Pain();
            SKUL E 0 EndAttack();
            SKUL EEEEEEE 3 {
                invoker.angle += 45;
            }
            SKUL E 0 A_JumpIf(frandom(0,1) < 0.5,"Pain");
            Goto See;

        Death:
            SKUL F 6 A_ScreamAndUnblock();
            SKUL GHIJK 5;
            Stop;
    }
}

class SkullyFire : Actor {
    // Lingers for a bit, slowing down over time.
    default {
        +BRIGHT;
        Projectile;
        +SHOOTABLE;
        -NOBLOCKMAP;
        +NOBLOOD;
        +THRUSPECIES; // To prevent them from self-detonating.
        FloatSpeed 8;
        Health 10;
        Radius 16;
        Height 32;
        DamageFunction (25);
        ReactionTime 105;
    }

    void FireDrift() {
        // Gradually slows down, drifting slightly downward...
        double spd = vel.xy.length();
        double vz = vel.z;
        double grav = clamp(GetAge()/3.,1,2);
        VelFromAngle(spd - 0.5,angle);
        if (vel.z > -grav) { vel.z -= 0.2; }
        // Also countdown.
        // A_CountDown();
    }

    states {
        Spawn:
            FYR2 AAAABBBB 1 FireDrift();
            Loop;
        
        Death:
            CHFR A 3 A_StartSound("Weapons/NailBomb");
            CHFR BCDEFGHIJKLMNOP 3;
            TNT1 A 0;
            Stop;
    }
}