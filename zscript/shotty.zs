class ShotgunThug : DMDMonster replaces ShotgunGuy {
    // He's gathered round yo' spawnpoint, with a pocket full o' shells...
    // 1. Fires two blasts from his boomstick, each doing 4x10 damage. However, the shards from this boomstick blast don't fly very far...
    // 2. So at longer ranges, he charges up a slug shot that does 1x40 damage.
    // 3. He also has a pocket full of barrels. The next time he tries to use this attack, he'll try to detonate the barrel.

    Actor barrel; // MORE POWDER!

    default {
        Health 45; // Tankier than the vanilla one, just like the zombie grunt.
        Radius 20;
        Height 56;
        Mass 150; // Slightly heavier.
        Speed 10; // Just as fast as the zombie grunt.
        PainChance 200; // Less flinchy than the grunt, more flinchy than normal.
		+FLOORCLIP
		SeeSound "shotguy/sight";
		AttackSound "shotguy/attack";
		PainSound "shotguy/pain";
		DeathSound "shotguy/death";
		ActiveSound "shotguy/active";
		Obituary "%o got ganked by a shotgun thug.";
		Tag "Shotgun Thug";
		DropItem "Shotgun";
        DropItem "Shell", 128;
        DropItem "HealthBonus", 128;
        DropItem "ArmorBonus", 128;
    }

    action void FireBuck() {
        A_StartSound("shotguy/attack");
        for (double i = -20; i < 20; i += 10) {
            Shoot("BuckPellet",aoffs:(i,0));
        }
    }

    action void FireSlug() {
        A_StartSound("shotguy/attack");
        Shoot("SlugPellet");
    }

    action void ThrowBarrel() {
        bool result;
        [result,invoker.barrel] = A_SpawnItemEX("ExplosiveBarrel",32,xvel:10,zvel:10);
    }

    override State ChooseAttack() {
        if (frandom(0,1) < .3) {
            // Barrel time!
            if (barrel) {
                if (target.Vec3To(barrel).length() < 320) {
                    console.printf("Shotgun Thug: [evil laughter]");
                    return ResolveState("BarrelShot");
                } else {
                    console.printf("Shotgun Thug: 'You cannot hide!'");
                    return ResolveState("Slug");
                }
            } else {
                console.printf("Shotgun Thug: 'BARREL!'");
                return ResolveState("Barrel");
            }
        } else {
            // Check range.
            if (Vec3To(target).length() < 320) {
                console.printf("Shotgun Thug: 'Die, worm!'");
                return ResolveState("Blast");
            } else {
                console.printf("Shotgun Thug: 'You cannot hide!'");
                return ResolveState("Slug");
            }
        }
    }

    states {
        Spawn:
            SPOS AB Random(6,8) A_Look();
            Loop;
        
        See:
            SPOS ABCD 3 A_Move();
            Loop;
        
        Missile:
            SPOS A 4 StartAttack();
            Goto See;
        
        Blast:
            SPOS E 6 A_StartSound("shotguy/sight");
            SPOS E 12 Aim();
            SPOS F 5 Bright FireBuck();
            SPOS E 10 Aim(15);
            SPOS F 5 Bright FireBuck();
            SPOS E 10;
            Goto See;

        Slug:
            SPOS E 8 A_StartSound("shotguy/pain");
            SPOS E 8 A_StartSound("weapons/sshotgc");
            SPOS E 3 Aim();
            SPOS EEE 2 Aim(2,2);
            SPOS F 5 Bright FireSlug();
            SPOS E 10;
            Goto See;

        Barrel: 
            SPOS G 5 A_StartSound("shotguy/pain");
            SPOS G 5 Aim();
            SPOS D 10 ThrowBarrel();
            SPOS E 10 EndAttack();
            Goto See;

        BarrelShot:
            SPOS E 6 A_StartSound("shotguy/sight");
            SPOS E 8 A_Face(barrel,0,0,flags:FAF_MIDDLE);
            SPOS F 5 Bright FireSlug();
            SPOS E 10;
            Goto See;

        Pain:
            SPOS G 4;
            SPOS H 3 A_Pain();
            SPOS E 6;
            SPOS F 5 Bright FireBuck();
            SPOS E 10 EndAttack();
            Goto See;
        
        Death:
            SPOS G 4;
            SPOS H 5 A_Scream();
            SPOS I 5 A_NoBlocking();
            SPOS J 4;
            SPOS K 4;
            SPOS L 1 A_StartSound("misc/thud");
            SPOS L -1;
            Stop;
        XDeath:
            SPOS G 4 A_Scream();
            SPOS M 4 A_XScream();
            SPOS N 4 A_NoBlocking();
            SPOS OPQRST 4;
            SPOS U -1;
            Stop;

        Raise:
            SPOS KJIH 5;
            SPOS G 3 A_Pain();
            Goto See;
    }
}

class BuckPellet : GruntBullet {
    default {
        DamageFunction (10);
        ReactionTime 10;
    }

    states {
        Spawn:
            BLR1 A 1 {
                // SpawnTrail(8,12,"FFCC00");
                A_CountDown();
            }
            Loop;
        
        Death:
            BLRE ABCDEF 2;
            Stop;
    }
}

class SlugPellet : GruntBullet {
    default {
        DamageFunction (40);
    }

    action void SpawnSparks() {
        vector2 dir = (frandom(-1,1),frandom(-1,1)).unit();
        double dist = frandom(1,5);
        A_SpawnItemEX("SlugSpark",yofs:dir.x*dist,zofs:dir.y*dist,yvel:dir.x*(5-dist),zvel:dir.y*(5-dist));
    }

    states {
        Spawn:
            BLR5 ABCD 3 SpawnSparks();
            Loop;
    }
}

class SlugSpark: Actor {
    default {
        +NOINTERACTION;
        Scale 0.5;
    }

    states {
        Spawn:
            BLRE ABCDEF 2;
            Stop;
    }
}