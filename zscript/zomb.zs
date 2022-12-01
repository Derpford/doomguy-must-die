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
        double dist = Vec3To(target).length();
        if (frandom(0,1) * dist >= 256) {
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
        A_SpawnItemEX("GruntNade",32,zofs:24,xvel:5,zvel:10);
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
            POSS E 3 EndAttack();
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
    mixin RadiusPush;
    default {
        // Projectile;
        +SHOOTABLE;
        +SOLID;
        Height 10;
        Radius 10;
        Health 10;
        -NOGRAVITY;
        Speed 25;
        // DamageFunction (5);
        Obituary "%o got bonked by a grunt's concussion grenade. Humiliating.";
    }

    override void Tick() {
        super.Tick();
        ThinkerIterator it = ThinkerIterator.Create("PlayerPawn");
        Actor mo;
        while (mo = Actor(it.next())) {
            if (Vec3To(mo).length() <= 128) {
                self.A_Die();
                break;
            }
        }
    }

    states {
        Spawn:
            BOMB A 35 {
                for (int i = 0; i < 360; i += 60) {
                    A_SpawnParticle("FF0000",SPF_FULLBRIGHT|SPF_RELPOS,15,8,i,8,zoff:12);
                }
            }
            Loop;
        Death:
            BOMB A 10;
            PLSE A 0 RadiusPush(20,256,-15);
            PLSE ABCDE 4 Bright;
            TNT1 A -1;
            Stop;
    }
}