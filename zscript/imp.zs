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
        Monster;
        +FLOORCLIP;
        SeeSound "imp/sight";
		PainSound "imp/pain";
		DeathSound "imp/death";
		ActiveSound "imp/active";
        Tag "Flame Imp";
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
    }

    override void Tick() {
        super.Tick();
        if (!bDECEASED) {
            double ang = GetAge() * 5;
            double zoff = 32 + sin(ang) * 4;
            if (ball1) { ball1.Warp(self,40,zofs:zoff,angle:ang); }
            if (ball2) { ball2.Warp(self,40,zofs:zoff,angle:ang + 120); }
            if (ball3) { ball3.Warp(self,40,zofs:zoff,angle:ang + 240); }
        } else {
            // Fireballs fly off when imp is dead
            if (ball1) { ball1.VelFromAngle(ball1.speed,AngleTo(ball1)); }
            if (ball2) { ball2.VelFromAngle(ball2.speed,AngleTo(ball2)); }
            if (ball3) { ball3.VelFromAngle(ball3.speed,AngleTo(ball3)); }
        }
    }

    states {
        Spawn:
            TROO AB Random(8,12) A_Look();
            Loop;
        
        See:
            TROO ABCD 3 A_Chase();
            Loop;
        
        Missile:
            TROO A 3 StartAttack();
            Goto See;
        
        Fireball:
            TROO E 4 A_StartSound("imp/sight");
            TROO E 4 Aim();
            TROO EEEE 2 Aim(5,1);
            TROO F 4;
            TROO G 5 FireBall();
            TROO EEE 2 Aim(5,1);
            TROO F 4;
            TROO G 5 FireBall();
            TROO G 10 EndAttack();
            Goto See;
        
        FireOrbit:
            TROO E 10 A_StartSound("imp/pain");
            TROO F 10 FireOrbit();
            TROO F 10 EndAttack();
            Goto See; 

        Lunge:
            TROO E 6 A_StartSound("imp/sight");
            TROO E 6 Aim();
            TROO F 6 Vel3DFromAngle(20,angle,pitch-15);
            Goto See;
        
        Pain:
            TROO H 2 {
                double ang = invoker.angle;
                if (frandom(0,1) > .5) {
                    ang += 90;
                } else {
                    ang -= 90;
                }
                invoker.Thrust(5,ang);
            }
            TROO H 3 A_Pain;
            TROO H 5 EndAttack();
            Goto See;
        Death:
            TROO H 8 A_Scream;
            TROO I 4;
            TROO J 4;
            TROO K 3;
            TROO L 3 A_NoBlocking;
            TROO M 1 A_StartSound("misc/thud");
            TROO M -1;
            Stop;
        XDeath:
            TROO H 8;
            TROO N 4;
            TROO O 3 A_XScream;
            TROO P 3;
            TROO Q 3 A_NoBlocking;
            TROO RST 3;
            TROO U -1;
            Stop;
        Raise:
            TROO ML 8 A_Pain();
            TROO KJI 6;
            Goto See;
    }
}

class ImpFireball : Actor {
    mixin ParticleTracer;

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
            BAL1 AAABBB 1 Smoke();
            Loop;
        
        Death:
            BAL1 C 6 Bright A_StartSound("imp/shotx");
            BAL1 D 7 Bright;
            BAL1 E 8 Bright;
            Stop;
    }
}

class ImpOrball : ImpFireball {
    // This one's on a timer!
    default {
        ReactionTime 175;
    }

    states {
        Spawn:
            BAL1 AAABBB 1 {
                A_CountDown();
                Smoke();
            }
            Loop;
    }
}