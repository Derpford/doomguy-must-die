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
        Speed 7; // And slightly slower...
        PainChance 100; // Harder to flinch than normal.
    }

    override State ChooseAttack() {
        if (CheckLOF()) {
            return ResolveState("SoulBurst");
        } else if (totem) {
            return ResolveState("SoulBurstTotem");
        } else {
            return ResolveState("TotemToss");
        }
    }

    void SoulShot(int count) {
        double anglebase = 15.;
        Vector2 spread = (5,5);
        Vector2 offs;
        SoulBall ball;

        switch (count) {
            case 0:
                offs = (anglebase*2,0);
                break;
            case 1:
                offs = (anglebase,-anglebase);
                break;
            case 2:
                offs = (-anglebase,-anglebase);
                break;
            case 3:
                offs = (-anglebase*2,0);
                break;
        }

        ball = SoulBall(Shoot("SoulBall",30,spread,offs));
        ball.goal = (angle,pitch);
        
    }

    states {
        Spawn:
            NLBC AB Random(10,16) A_Look();
            Loop;
        
        See:
            NLBC ABCD 4 A_Chase();
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

    }
}

class SoulBall : Actor {
    // A projectile that steadily curves toward a goal angle.
    vector2 goal;
    default {
        Projectile;
        DamageFunction (25);
        RenderStyle "Add";
    }

    void TurnGoal() {
        double da = DeltaAngle(angle,goal.x);
        double asign = da / abs(da);
        double dp = DeltaAngle(pitch,goal.y);
        double psign = dp / abs(dp);

        angle += min(da, 5*asign);
        pitch += min(dp, 5*psign);
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