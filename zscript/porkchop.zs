class Porkchop : DMDMonster replaces Fatso {
    // A big ol' piggy who's in the mood for sandwiches.
    // Oh shit, get the fuck outta there--
    // 1. His smog launchers fire canisters that douse an area in oily smog. 
    // Smog can be ignited by AoE damage, causing it to deal AoE damage over a short while.
    // 2. He can ignite that smog with an exploding, bouncing fireball attack.
    // This fireball does 64 damage in a 64-unit AoE.
    // Fun fact: that's a max-damage mancubus fireball! And he fires 3 in a spread.

    int smogshots;

    default {
        Health 500; // Slightly less tanky than the original.
        Radius 48; // Just as big, though.
        Height 48; // Quadrupeds are shorter.
        Mass 700; // Relatively light-weight.
        Speed 6; // Slower.
        PainChance 100; // Like most of these monsters, tends to flinch more.
        +BOSSDEATH; // Gotta have vanilla map compat.
        SeeSound "PPork/See";
        ActiveSound "PPork/Act";
        PainSound "PPork/Pai";
        DeathSound "PPork/Ded";
    }

    override State ChooseAttack() {
        // Each time it fires a smog round, the smog round chance gets lower.
        if (random(-3,3) > smogshots) {
            return ResolveState("SmogShot");
        } else {
            return ResolveState("FireShot");
        }
    }

    void FireSmog() {
        A_StartSound("weapons/grenlf");
    }

    void FireBallSides() {
        A_StartSound("fatso/attack");
    }

    void FireBallMid() {
        A_StartSound("fatso/attack");
    }

    states {
        Spawn:
            PPRK AB Random(6,12) A_Look();
            Loop;
        
        See:
            PPRK ABCD 3 A_Chase();
            Loop;
        
        Missile:
            PPRK E 4 StartAttack();
            Goto See;

        SmogShot:
            PPRK E 5 Aim();
            PPRK E 10 A_StartSound("PPork/See");
            PPRK F 4 FireSmog(); // TODO: actual shot
            PPRK E 8 EndAttack();
            Goto See;
        
        FireShot:
            PPRK E 2 A_StartSound("PPork/Pai");
            PPRK EEE 5 Aim();
            PPRK F 3 FireBallSides(); // TODO: actual shot
            PPRK E 15;
            PPRK F 3 FireBallMid(); // TODO: actual shot
            PPRK E 8 EndAttack();
            Goto See;
        

    }
}