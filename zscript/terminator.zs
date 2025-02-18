class Terminator : DMDMonster replaces Arachnotron {
    // A powerful biomechanical war machine, designed specifically to ruin your day.
    // 1. It can launch a Plasma Star, which fires 10 plasma bolts before dissipating. Each bolt does 40 damage.
    // 2. It also carries a powerful Microwave Beam Cannon, which superheats the ground to cause massive explosions. It takes a second or two for the explosions to go off, but in total, 5 chunks of ground will blow up for 128 in a 128 radius.
    // 3. Finally, the belt-fed machine gun built into the same housing as the MBC allows the Terminator to attack directly, even when the Plasma Star and MBC are on cooldown. Similar stats to Grunt burst rifle, but fires in longer bursts.

    int starwait;
    int mbcwait; // The Terminator must perform X attacks before it can use the Plasma Star or MBC again.

    double bracketangle; // the angle offset for bracketing fire with the MG.

    default {
        Health 500;
        Radius 56;
        Height 64;
        Mass 500;
        Speed 20; // To make up for stopping with every step.
        PainChance 64;
        +BOSSDEATH;
        SeeSound "monster/termsit";
        ActiveSound "monster/termact";
        PainSound "monster/termpin";
        DeathSound "monster/termdth";
    }

    State TryMBC() {
        if (mbcwait < 1) {
            mbcwait = 3;
            return ResolveState("MBC");
        } else {
            return ResolveState("Guns");
        }
    }

    State TryStar() {
        if (mbcwait < 1) {
            mbcwait = 3;
            return ResolveState("Star");
        } else {
            return ResolveState("Guns");
        }
    }

    void SpawnBits() {
        // TODO: Spawn arm and head.
        A_SpawnItemEX("TermHelmet",zofs:64,xvel:frandom(-4,4),yvel:frandom(-4,4),zvel:frandom(8,12));
        A_SpawnItemEX("TermArm",yofs:48,zofs:64,xvel:frandom(-4,4),yvel:frandom(8,12),zvel:frandom(6,8));
    }

    override State ChooseAttack() {
        State res;
        if (frandom(0,1) >= 0.5) {
            res = TryMBC();
        } else {
            res = TryStar();
        }
        mbcwait -= 1;
        starwait -= 1;
        return res;
    }

    void FireStar() {
        A_StartSound("monster/brufir");
        // TODO: Fire a plasma star
        Shoot("PlasmaStar");
    }

    void FireMBC(vector2 offs) {
        A_StartSound("Terminator/tershotA");
        // TODO: 0-damage railgun with explosive puff
        A_CustomRailgun(0,-16,"FF0000","FF4444",RGF_EXPLICITANGLE|RGF_SILENT|RGF_NORANDOMPUFFZ,0,0,"MBCPuff",offs.x,offs.y);
    }

    void SetupGuns() {
        bracketangle = 20;
        if (frandom(0,1) > 0.5) {
            bracketangle *= -1;
        }
    }

    void FireGuns() {
        A_StartSound("Terminator/tershotB");
        if (bracketangle > 0) {bracketangle--;}
        if (bracketangle < 0) {bracketangle++;}
        LineShoot("GruntBullet",4,12,poffs:((-16,0)));
    }
    
    states {
        Spawn:
            TERM AE Random(8,12) A_Look();
            Loop;
        
        See:
            TERM A 5 A_Move();
            TERM A 10 A_StartSound("Terminator/terstepA",5);
            TERM B 5 A_Move();
            TERM C 5 A_Move();
            TERM C 10 A_StartSound("Terminator/terstepA",6);
            TERM D 5 A_Move();
            Loop;
        
        Missile:
            TERM A 3 StartAttack();
            Goto See;

        Star:
            TERM E 15 Aim();
            TERM F 5 Bright FireStar();
            TERM E 25 EndAttack();
            Goto See;
        
        MBC:
            TERM J 10 Aim(flags:FAF_BOTTOM);
            TERM K 3 Bright FireMBC((-15,2));
            TERM J 1;
            TERM K 3 Bright FireMBC((-10,1));
            TERM J 1;
            TERM K 3 Bright FireMBC((0,0));
            TERM J 1;
            TERM K 3 Bright FireMBC((10,1));
            TERM J 1;
            TERM K 3 Bright FireMBC((15,2));
            TERM J 15 EndAttack();
            Goto See;
        
        Guns:
            TERM G 0 SetupGuns();
            TERM G 10 Aim(offs:(bracketangle,0));
        GunsFire:
            TERM H 1 Bright FireGuns();
            TERM I 1 Bright;
            TERM G 1 Aim(10+abs(bracketangle),5,offs:(bracketangle,0));
            TERM G 0 A_JumpIf((frandom(1,abs(bracketangle)) <= 0.1), "GunsEnd");
            Loop;
        GunsEnd:
            TERM G 10 EndAttack();
            Goto See;

        Pain:
            TERM L 16 A_Pain();
            TERM A 4 EndAttack();
            Goto Missile;
        
        Death:
        XDeath:
            TERM L 0 Aim();
            TERM L 4 A_Pain();
            TERM LLLLLLLLL 4 A_SpawnItemEX("HeatSmoke");
            TERM M 4 A_ScreamAndUnblock();
            TERM NOPQ 4 Bright;
            TERM R 4 Bright SpawnBits();
            TERM STU 4 Bright;
            TERM VWXYZ 4;
            TERM "[" -1 A_BossDeath();
            Stop;
    }
}

class TermHelmet : Actor {
    mixin FallingDebris;
    default {
        BounceType "Doom";
    }

    override void Tick() {
        Super.Tick();
        ProcessFall();
    }

    states {
        Spawn:
            THAD ABCDEFGH 4;
            Loop;
        Crash:
            THAD I -1;
            Stop;
    }
}

class TermArm : Actor {
    mixin FallingDebris;
    override void Tick() {
        Super.Tick();
        ProcessFall();
    }
    states {
        Spawn:
            TARM AB 12;
        Fall:
            TARM C 1;
            Loop;
        Crash:
            TARM DEF 5;
        End:
            TARM F -1;
            Stop;
    }
}

class TermBullet : GruntBullet {
    // Has its own obituary.
    default {
        Obituary "%o got perforated by a terminator.";
    }
}

class PlasmaStar : Actor {
    // Fires ten plasma bolts before dissipating.
    mixin Shooter;

    default {
        ReactionTime 10;
        +NOGRAVITY;
        +WALLSPRITE;
        RenderStyle "Add";
    }

    void FireBolt() {
        A_StartSound("monster/brufir");
        Shoot("PlasmaBolt",20,(7,10));
    }

    states {
        Spawn:
            STAR ABCDABCD 3;
        Fire:
            STAR A 3 Bright FireBolt();
            STAR BC 3 Bright;
            STAR D 3 Bright A_CountDown();
            Loop;
        
        Death:
            STAR EFGHIJKLMNO 3 Bright;
            TNT1 A 0;
            Stop;
    }
}

class PlasmaBolt : Actor {
    // Pew pew.
    default {
        Projectile;
        DamageFunction (40);
        RenderStyle "Add";
        Obituary "%o stood in front of a terminator's plasma star.";
    }

    states {
        Spawn:
            BLST A 1;
            Loop;
        Death:
            BLST BCDEFGHIJKL 2;
            TNT1 A 0;
            Stop;
    }
}

class MBCPuff : BulletPuff {
    // Explodes after a bit.
    default {
        // TODO: Flatsprite?
        +ALWAYSPUFF;
        Obituary "%o was nuked by a terminator's microwave beam cannon.";
    }

    action void SpawnGlow() {
        double zofs = invoker.pos.z - invoker.floorz;
        if (zofs <= 16) { // Only spawn the floor glow if it makes sense.
            A_SpawnItemEX("MBCGlow",zofs:-zofs);
        } else {
            A_SpawnItemEX("MBCAirGlow");
        }
    }

    states {
        Spawn:
            TNT1 A 0;
            TNT1 A 5 SpawnGlow();
            TNT1 AAAAA 5;
            BLST B 5 Bright;
            BLST C 5 Bright A_Explode(128);
            BLST C 0 Bright A_StartSound("weapons/hellex");
            BLST DEFGHIJ 5 Bright;
            TNT1 A 0;
            Stop;
    }
}

class MBCGlow : Actor {
    // Glowy effect on the ground.
    default {
        +NOINTERACTION;
        +FLATSPRITE;
        +BRIGHT;
        Scale 3;
        Alpha 0.5;
        RenderStyle "Add";
    }

    states {
        Spawn:
            PLS2 BBBBBB 5 {
                A_SpawnItemEX("HeatSmoke",zofs:8,zvel:4);
                invoker.alpha += 0.1;
            }
            Stop;
    }
}

class MBCAirGlow : MBCGlow {
    default {
        -FLATSPRITE; // Midair glow.
    }
}

class HeatSmoke : Actor {
    default {
        +NOINTERACTION;
        RenderStyle "Translucent";
        Alpha 0.5;
    }

    states {
        Spawn:
            RSMK ABCDE random(3,5) {
                vel.z += 1;
                vel.x += frandom(-4,4);
                vel.y += frandom(-4,4);
                A_FadeOut();
            }
            Loop;
    }
}