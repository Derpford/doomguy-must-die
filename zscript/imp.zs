class FlameImp : DMDMonster replaces DoomImp {
    // Now with a little more close-range threat.
    // 1. Hurls two fireballs in rapid succession for 2x20 damage.
    // 2. Summons three orbiting fireballs which do 3x20 damage, but wear off over time.

    Actor ball1;
    Actor ball2;
    Actor ball3;

    default {
        Health 60;
        Radius 20;
        Height 56;
        Speed 8;
        PainChance 200;
        +FLOORCLIP;
        SeeSound "monster/hlnsit";
		PainSound "monster/hlnpai";
		DeathSound "monster/hlndth";
		ActiveSound "monster/hlnact";
        Tag "Flame Imp";
        DropItem "HealthBonus";
        DropItem "ArmorBonus";
    }

    override State ChooseAttack() {
        if (random(0,60) >= health) {
            if (ball1 || ball2 || ball3) {
                return ResolveState("Lunge");
            } Else {
                return ResolveState("FireOrbit");
            }
        } else {
            return ResolveState("Fireball");
        }
    }

    action void FireBall() {
        A_StartSound("imp/attack");
        Shoot("ImpFireball");
    }

    action void FireOrbit() {
        A_StartSound("imp/attack");
        invoker.ball1 = Spawn("ImpOrball",invoker.pos);
        invoker.ball2 = Spawn("ImpOrball",invoker.pos);
        invoker.ball3 = Spawn("ImpOrball",invoker.pos);
        invoker.ball1.target = invoker;
        invoker.ball2.target = invoker;
        invoker.ball3.target = invoker;
        invoker.ball1.angle = angle;
        invoker.ball2.angle = angle + 120;
        invoker.ball3.angle = angle + 240;

    }

    states {
        Spawn:
            HELN AB Random(8,12) A_Look();
            Loop;
        
        See:
            HELN ABCDEF 3 A_Move();
            Loop;
        
        Missile:
            HELN A 3 StartAttack();
            Goto See;
        
        Fireball:
            HELN G 3 Bright A_StartSound("monster/hlnatk",2);
            HELN H 3 Bright;
            HELN I 3 Bright Aim();
            HELN J 3 Bright;
            HELN JJJJ 2 Aim(5,1);
            HELN K 4;
            HELN L 5 FireBall();
            HELN JJJ 2 Aim(5,1);
            HELN K 4;
            HELN L 5 FireBall();
            HELN L 10 EndAttack();
            Goto See;
        
        FireOrbit:
            HELN G 2 Bright A_StartSound("monster/hlnpai",2);
            HELN HIJK 2 Bright;
            HELN L 10 FireOrbit();
            HELN L 10 EndAttack();
            Goto See; 

        Lunge:
            HELN B 6 A_StartSound("monster/hlnpai",2);
            HELN B 6 Aim();
            HELN F 6 Vel3DFromAngle(20,angle,pitch-15);
            HELN E 6 EndAttack();
            Goto See;
        
        Pain:
            HELN M 4;
            HELN M 2 {
                double ang = invoker.angle;
                state dodge;
                if (frandom(0,1) > .5) {
                    ang += 90;
                    dodge = ResolveState("DodgeLeft");
                } else {
                    ang -= 90;
                    dodge = ResolveState("DodgeRight");
                }
                invoker.Thrust(5,ang);
                return dodge;
            }
        DodgeLeft:
            HELN A 5 A_Pain();
            Goto PainEnd;
        DodgeRight:
            HELN D 5 A_Pain();
            Goto PainEnd;
        PainEnd:
            HELN H 5 EndAttack();
            Goto See;
        Death:
            HELN M 8 A_Scream;
            HELN N 4;
            HELN O 4;
            HELN P 3;
            HELN Q 3 A_NoBlocking;
            HELN R 1 A_StartSound("misc/thud");
            HELN S 1;
            HELN T -1;
            Stop;
        XDeath:
            HELN M 8;
            HELN N 4;
            HELN U 3 A_XScream;
            HELN V 3;
            HELN W 3 A_NoBlocking;
            HELN XYZ 3;
            HEL2 ABC 2;
            HEL2 C -1;
            Stop;
        Raise:
            HELN SR 8 A_Pain();
            HELN QPOMN 6;
            Goto See;
    }
}

class ImpFireball : Actor {

    action void Smoke() {
        A_SpawnParticle("333333",SPF_RELATIVE|SPF_FULLBRIGHT,35,8,0,-8,frandom(-8,8),frandom(-8,8));
    }

    default {
        Speed 15;
        DamageFunction (20);
        Projectile;
        Radius 6;
        Height 8;
        RenderStyle "Add";
        Decal "DoomImpScorch";
        Obituary "%o was fried by an imp.";
    }

    states {
        Spawn:
            HLBL AAABBB 1 Smoke();
            Loop;
        
        Death:
            HLBL C 1 Bright A_StartSound("imp/shotx");
            HLBL DEFGHI 1 Bright;
            HLBL JKLMN 2 Bright;
            Stop;
    }
}

class ImpOrball : ImpFireball {
    // This one's on a timer!
    default {
        ReactionTime 175;
    }

    override void Tick() {
        Super.Tick();
        if(InStateSequence(curstate,ResolveState("Spawn"))) {
            if(target) {
                // Orbit our owner!
                angle += 5;
                VelFromAngle(1,angle+90);
                Warp(target,40,zofs:32,angle:angle,flags:WARPF_ABSOLUTEANGLE|WARPF_INTERPOLATE);
            } else {
                // Owner's dead. Fly off into the distance!
                bSPRITEANGLE = false;
                VelFromAngle(speed,angle);
            }
        }
    }

    states {
        Spawn:
            HLBL AAABBB 1 {
                A_CountDown();
                Smoke();
            }
            Loop;
        Death:
            HLBL C 1 Bright A_StartSound("imp/shotx");
            HLBL DEFGHI 1 Bright;
            HLBL JKLMN 2 Bright;
            Stop;
    }
}