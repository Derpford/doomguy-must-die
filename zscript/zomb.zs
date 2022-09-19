class ZombieGrunt : DMDMonster replaces ZombieMan {
    // Stronger than the base zombie, but not by much.
    // Has two attacks:
    // 1. Three-shot burst for 3x15 damage, total of 45. Yes, this means that the base zombie can kill you with 3 attacks.
    // 2. Toss a concussion grenade that bounces everyone in a wide radius, including the guy who threw it.

    default {
        Health 30; // Slightly harder to kill...
        Radius 20;
        Height 56;
        Speed 10; // Slightly faster, too!
        PainChance 220; // Slightly easier to flinch, though.
        Monster;
        +FLOORCLIP;
        SeeSound "grunt/sight";
        AttackSound "grunt/attack";
        PainSound "grunt/pain";
        DeathSound "grunt/death";
        ActiveSound "grunt/active";
        Tag "Zombie Grunt";
        DropItem "Clip";
        DropItem "Clip", 128;
        DropItem "HealthBonus",128;
    }

    override State ChooseAttack() {
        if (Vec3To(target).length() < 256 && frandom(0,1) < .3) {
            return ResolveState("Grenade");
        } else {
            return ResolveState("BurstShot");
        }
    }

    void FireBullet() {
        A_StartSound("grunt/attack");
        Shoot("GruntBullet");
    }

    void FireGrenade() {
        A_StartSound("player/male/fist");
        Shoot("GruntNade");
    }

    states {
        Spawn:
            POSS AB Random(8,12) A_Look();
            Loop;
    
        See:
            POSS ABCD 3 A_Chase();
            Loop;
        
        Missile:
            POSS A 3 StartAttack();
            Goto See;
        
        BurstShot:
            POSS E 6 A_StartSound("grunt/sight");
            POSS E 4 Aim();
            POSS EEEEE 2 Aim(3,5);
            POSS E 4;
            POSS F 4 Bright FireBullet();
            POSS E 2;
            POSS F 4 Bright FireBullet();
            POSS E 2;
            POSS F 4 Bright FireBullet();
            POSS E 10 EndAttack();
            Goto See;
        
        Grenade:
            POSS A 0 A_StartSound("grunt/pain");
            POSS A 8 Aim(0,270); // Grenade always aims horizontally.
            POSS BCD 3;
            POSS D 3 FireGrenade();
            POSS D 20 EndAttack();
            Goto See;

        Pain:
            POSS G 3 Thrust(-5, invoker.angle);
            POSS G 5 A_Pain();
            Goto See;
        
        Death:
            POSS G 4;
            POSS H 5 A_Scream();
            POSS I 5 A_NoBlocking();
            POSS J 4;
            POSS K 4;
            POSS L 1 A_StartSound("misc/thud");
            POSS L -1;
            Stop;
        XDeath:
            POSS G 4 A_Scream();
            POSS M 4 A_XScream();
            POSS N 4 A_NoBlocking();
            POSS OPQRST 4;
            POSS U -1;
            Stop;

        Raise:
            POSS KJIH 5;
            POSS G 3 A_Pain();
            Goto See;
    }
}

class GruntBullet : Actor {
    mixin ParticleTracer;
    default {
        Projectile;
        Speed 40;
        Radius 2;
        Height 4;
        DamageFunction (15);
        Obituary "%o underestimated a grunt.";
        Decal "BulletChip";
    }

    states {
        Spawn:
            TNT1 A 1 SpawnTrail(6,16,"FFFF00");
            Loop;
        Death:
        Crash:
            PUFF ABCD 3;
            TNT1 A -1;
            Stop;
        
        XDeath:
            BLOD DCBA 4;
            TNT1 A -1;
            Stop;
    }
}

class GruntNade : Actor {
    mixin ParticleTracer;
    default {
        Projectile;
        -NOGRAVITY;
        Speed 25;
        DamageFunction (5);
        Obituary "%o got bonked by a grunt's concussion grenade. Humiliating.";
    }

    states {
        Spawn:
            BOMB A 1 SpawnTrail(8,12,"333333",spread:(6,6,6));
            Loop;
        Death:
            BOMB A 10;
            PLSE A 0 A_RadiusThrust(500,256,RTF_AFFECTSOURCE|RTF_NOIMPACTDAMAGE,256);
            PLSE A 0 A_RadiusThrust(100,256,RTF_AFFECTSOURCE|RTF_NOIMPACTDAMAGE|RTF_THRUSTZ,256);
            PLSE ABCDE 4 Bright;
            TNT1 A -1;
            Stop;
    }
}