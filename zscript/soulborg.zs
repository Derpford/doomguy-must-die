class SoulBorg : DMDMonster replaces ChaingunGuy {
    // A cybernetic freak powered by magitek.
    // 1. His primary attack fires a spread of four souls, which follow a parabolic arc toward their target. Each one does 24 damage.
    // 2. He can also summon a Pain Totem. Enemy attacks that hit the Pain Totem cause it to fire soul blasts at its owner's target. Damage from a player is fired toward the soul totem's owner instead!

    Actor totem;

    default {
        Health 70;
        Radius 20;
        Height 56;
        Mass 120; // A little heavier than normal.
        Speed 10; // And slightly faster.
        PainChance 100; // Harder to flinch than normal.
        SeeSound "Monsters/NBSight";
        ActiveSound "Monsters/NBAct";
        PainSound "Monsters/NBPain";
        DeathSound "Monsters/NBDeath";
        DropItem "Chaingun";
        DropItem "Stimpack", 128;
        DropItem "Clip", 128;
        DropItem "HealthBonus", 192;
    }

    override State ChooseAttack() {
        if (CheckLOF() && frandom(0,1) <= 0.3) {
            return ResolveState("SoulBurst");
        } else if (totem && totem.health > 0) {
            totem.tracer = target;
            if (Vec3To(totem).length() > 64 && totem.CheckLOF(CLOFF_SKIPFRIEND,ptr_target: AAPTR_TRACER)) {
                return ResolveState("SoulBurstTotem");
            } else {
                return ResolveState(null); // Cancel the attack, it's not safe.
            }
        } else {
            return ResolveState("TotemToss");
        }
    }

    void SoulShot(int count) {
        A_StartSound("imp/attack",1);
        double anglebase = 10.0;
        Vector2 spread = (5,2.5);
        Vector2 offs;
        SoulBall ball;

        switch (count) {
            case 0:
                offs = (anglebase*2.0,0);
                break;
            case 1:
                offs = (anglebase,-anglebase);
                break;
            case 2:
                offs = (-anglebase*2.0,0);
                break;
            case 3:
                offs = (-anglebase,anglebase);
                break;
        }

        ball = SoulBall(Shoot("SoulBall",25,spread,offs));
        ball.goal = (angle,pitch);
        
    }

    void ThrowTotem() {
        totem = Shoot("SoulTotem",20,aoffs:(0,-10));
    }

    states {
        Spawn:
            NLBC AB Random(10,16) A_Look();
            Loop;
        
        See:
            NLBC ABCD 4 A_Chase();
            NLBC A 0 {
                if (frandom(0,1) <= 0.3) {
                    return ResolveState("Missile");
                } else {
                    return ResolveState(null);
                }
            }
            Loop;
        
        Missile :
            NLBC E 4 StartAttack();
            Goto See;

        Pain:
            NLBC G 10 A_Pain();
            NLBC E 5 EndAttack();
            Goto See;
        
        Death:
            NLBC G 7 A_Pain();
            NLBC H 6 A_Scream();
            NLBC I 5 A_NoBlocking();
            NLBC JKLMN 4;
            NLBC N -1;
            Stop;

        XDeath:
            NLBC G 6 A_Pain();
            NLBC O 5 A_ScreamAndUnblock();
            NLBC PQRST 4;
            NLBC T -1;
            Stop;
        
        SoulBurst:
            NLBC E 6 Aim();
        SoulBurstActual:
            NLBC E 4 A_StartSound("Monsters/NBSight");
            NLBC F 3 SoulShot(0);
            NLBC E 3;
            NLBC F 3 SoulShot(1);
            NLBC E 3;
            NLBC F 3 SoulShot(2);
            NLBC E 3;
            NLBC F 3 SoulShot(3);
            NLBC E 3 EndAttack();
            Goto See;

        TotemToss:
            NLBC A 5 {
                double aoffs = 45;
                if (frandom(0,1) >= 0.5) {
                    aoffs *= -1;
                }
                Aim(offs:(aoffs,0));
            }
            NLBC E 15 ThrowTotem(); 
            NLBC E 5 EndAttack();
            Goto See;

        SoulBurstTotem:
            NLBC E 6 A_Face(totem,0,0,flags:FAF_MIDDLE);
            Goto SoulBurstActual;

    }
}

class SoulBall : Actor {
    // A projectile that steadily curves toward a goal angle.
    vector2 goal;
    default {
        Projectile;
        Speed 20;
        DamageFunction (25);
        RenderStyle "Add";
    }

    void TurnGoal() {
        double turnspeed = 1;
        double da = DeltaAngle(angle,goal.x);
        double dp = DeltaAngle(pitch,goal.y);
        double aspeed = min(abs(da),turnspeed);
        double pspeed = min(abs(dp),turnspeed);
        double asign = 0;
        double psign = 0;
        if (da != 0) {
            asign = da / abs(da);
        }
        if (dp != 0) {
            psign = dp / abs(dp);
        }

        angle += aspeed * asign;
        pitch += pspeed * psign;
        Vel3DFromAngle(vel.length(),angle,pitch);
    }

    States {
        Spawn:
            SHBA AAABBB 1 TurnGoal();
            Loop;

        Death:
            SHBA CDEFGH 2;
            TNT1 A -1;
            Stop;
    }
}

class SoulTotem : Actor {
    // A freaky totem pole that radiates soul magic.
    // It has a mystical connection to its owner.

    int dmgcache; // How much damage has been taken? Every 25 damage, release a SoulBall.
    // The target is decided by whose damage broke the threshold--i.e., if you last-hit it, it's your ball.
    default {
        // +SOLID;
        +SHOOTABLE;
        +NOTARGETSWITCH;
        Health 100;
        Radius 20;
        Height 56;
    }

    void SpawnPuff() {
        A_SpawnItemEX("SoulPuff",xofs:frandom(16,32),zofs:frandom(48,56),angle:frandom(0,360));
    }

    override int DamageMobj(Actor inf, Actor src, int dmg, Name mod, int flags, double ang) {
        if (target && target.target) {
            dmgcache += dmg;
            while (dmgcache >= 25) {
                if (src is "PlayerPawn" || src is "DoomPlayer") {
                    // A player triggered this attack! Fire at our owner.
                    A_Face(target,0,0,flags:FAF_MIDDLE);
                    SoulBall ball = SoulBall(A_SpawnProjectile("SoulBall",angle:frandom(-20,20)));
                    ball.goal = (angle,pitch);
                } else {
                    // Fire at our owner's target.
                    tracer = target.target;
                    A_Face(tracer,0,0,flags:FAF_MIDDLE);
                    SoulBall ball = SoulBall(A_SpawnProjectile("SoulBall",angle:frandom(-20,20),ptr:AAPTR_TRACER));
                    ball.goal = (angle,pitch);
                }
                dmgcache -= 25; // Consume the damage.
            }
        }

        return super.DamageMobj(inf,src,dmg,mod,flags,ang);
    }

    states {
        Spawn:
            POL3 A 5 Bright;
            POL3 B 5 Bright SpawnPuff();
            Loop;
        Death:
            SHBA C 0 A_SetRenderStyle(1.0,STYLE_Add);
            SHBA CDEFGHIJKL 3 Bright SpawnPuff();
            TNT1 A -1 A_NoBlocking();
            Stop;
    }
}

class SoulPuff : Actor {
    // A puff of soul energy.
    default {
        +NOINTERACTION;
        RenderStyle "Add";
    }

    states {
        Spawn:
            SHGH ABCDEFG 3;
            TNT1 A -1;
            Stop;
    }
}